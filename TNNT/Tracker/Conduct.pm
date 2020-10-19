#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Conduct;

use Carp;
use Moo;
use TNNT::ScoringEntry;
use TNNT::Game;
use Data::Dump qw(dd);


#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'conduct',
);

has _player_track => (
  is => 'ro',
  default => sub { {} },
);

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return a ref to player tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
  }

  croak "Invalid argument to GreatFoo->_track($subj_type)";
}

#-----------------------------------------------------------------------------
# Return player/clan tracking entry. If it doesn't exist yet, new one is
# created and returned. The argument must be an instance of Player or Clan.
#-----------------------------------------------------------------------------

sub _track_data
{
  my ($self, $subj) = @_;

  if($subj->isa('TNNT::Player')) {
    if(!exists $self->_player_track()->{$subj->name()}) {
      return $self->_player_track()->{$subj->name()} = {};
    } else {
      return $self->_player_track()->{$subj->name()};
    }
  } else {
    croak 'Invalid argument to GreatFoo->track_data(), must be Player or Clan';
  }
}

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  #--- only ascended games

  return if !$game->is_ascended();
  my $player = $game->player();
  my $tracker = $self->_track_data($player);

  #--- get summary score for conducts
  # The composite multiplier formula for all conducts is
  # multiplier₁ × multiplier₂ × … × multiplierₙ - 1

  my $cfg = TNNT::Config->instance()->config();

  my @conducts = $game->conducts();
  if (scalar(@conducts) == 0) {
    return; # doesn't make sense to count conductless wins
  }
  my $conds_idx = $cfg->{'conducts'}{'order_idx'};
  my $cond_multi_array = $cfg->{'conducts'}{'multi_array'};
  my $conds_max = $cfg->{'conducts'}{'n_total'};
  push @{$tracker->{'condascs'}}, { 'key' => $game, 'conducts' => [$game->conducts()] };

  # fill an initial grid now, this will simply
  # contain 1 in each grid position with a conduct,
  # for the beginning
  my @conduct_grid = ();
  my @games = ();
  my $n_ascs = 0;
  foreach my $ascension (@{$tracker->{'condascs'}}) {
    push @conduct_grid, [(0) x $conds_max];
    push @games, $ascension->{'key'};
    foreach my $conduct (@{$ascension->{'conducts'}}) {
      my $cond_index = $conds_idx->{$conduct};
      $conduct_grid[$n_ascs][$cond_index] = 1;
    }
    $n_ascs += 1;
  }
  
  my (@zscores, @sorted_keys) = greedy_zscore(\@conduct_grid, $cond_multi_array, $conds_max, $n_ascs, \@games);
  for (my $i = 0; $i < @sorted_keys; $i++) {
    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      when => $game->endtime,
      points => 0,
      data => {
        conducts => [ $game->conducts() ],
        conducts_txt => join(' ', $game->conducts()),
        ncond => scalar($game->conducts()),
        multiplier => $zscores[$i],
        key => $sorted_keys[$i]
      }
    );

    if ($game == $sorted_keys[$i]) {
      $game->add_score($se);
    } else {
      $game->remove_and_add("key", $sorted_keys[$i], $se);
    }
  }
  #--- finish

  return $self;
}

sub greedy_zscore {
  my      ($grid,
    $multipliers,
        $m_conds,
         $n_ascs,
          $games) = @_;
  my @zfactors = (1) x $m_conds;
  my @zscores;
  my @games_copy = @$games;

  # $opt_index is updated each time an optimally-scoring game is found
  # from the set of remaining games
  for (my $opt_index = 0; $opt_index < $n_ascs; $opt_index++) {
    my $temp_best = 0;
    my $best_index = 0;
    my $score;
    # $test_index iterates through remaining games that don't have an optimised z-score
    # compute a trial conduct Z-score for each game, to see which is best
    for (my $test_index = $opt_index; $test_index < $n_ascs; $test_index++) {
      # for each conduct achieved ($grid->[$test_index][$cond_index] == 1),
      # multiply (cumulatively) $score by the multiplier defined for that conduct,
      # and the current Z-factor for the given conduct
      # grid cell value will simply equal 1 at this stage, so is left out
      $score = 1;
      for (my $cond_index = 0; $cond_index < $m_conds; $cond_index++) {
        if ($grid->[$test_index][$cond_index] != 0) {
          $score *= $zfactors[$cond_index] * $multipliers->[$cond_index];
        }
      }

      # is this the best score so far?
      # if yes, update $temp_best and $best_index
      if ($score > $temp_best) {
        $temp_best = $score;
        $best_index = $test_index;
      }
    }

    # now we should have the highest scoring game/index for the round,
    # unless that coincidentally happens to be at $opt_index already,
    # swap the entries
    if ($opt_index != $best_index) {
      # swap the positions
      my $token = $games_copy[$opt_index];
      $games_copy[$opt_index] = $games_copy[$best_index];
      $games_copy[$best_index] = $token;
      my $tmp = $grid->[$opt_index];
      $grid->[$opt_index] = $grid->[$best_index];
      $grid->[$best_index] = $tmp;
    }

    # now with the found optimum-score game, 
    $score = 1;
    for (my $cond_index = 0; $cond_index < $m_conds; $cond_index++) {
      if ($grid->[$opt_index][$cond_index] != 0) {
        # assign the current Z-factor for the conduct to the relevant cell
        $grid->[$opt_index][$cond_index] = $zfactors[$cond_index];
        # algorithm probably works fine without an actual grid, what's really
        # needed is just the z-score for each game, the z-factor array, and
        # an ordered list of the games. Having said that, someone may want
        # these grids for some esoteric purposes so i'll leave it as is for now
        $score *= $grid->[$opt_index][$cond_index] * $multipliers->[$cond_index];
        $zfactors[$cond_index] = 1/(1/$zfactors[$cond_index] + 1);
      }
    }
    push @zscores, $score;
  }

  # i think i also want to return some information about how the
  # games have been (re)ordered
  return @zscores;
}


sub finish
{
}



#=============================================================================

1;
