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
  my $game_index = $game->n();
  my $tracker = $self->_track_data($player);

  #--- get summary score for conducts
  # The composite multiplier formula for all conducts is
  # multiplier₁ × multiplier₂ × … × multiplierₙ - 1

  my $cfg = TNNT::Config->instance()->config();

  my $conds_idx = $cfg->{'conducts'}{'order_idx'};
  my $cond_multi_array = $cfg->{'conducts'}{'multi_array'};
  my $conds_max = $cfg->{'conducts'};
  my $first = 0;
  if (!%$tracker) {
    # flag this as first run - thus we only add score entry, rather than remove and add
    $first = 1;
  }
  push @{$tracker->{'condascs'}}, { 'index' => $game_index, 'conducts' => [$game->conducts()] };

  # fill an initial grid now, this will simply
  # contain 1 in each grid position with a conduct,
  # for the beginning
  my @conduct_grid = ();
  my @game_keys = ();
  my $n_ascs = 0;
  foreach my $ascension (@{$tracker->{'condascs'}}) {
    push @conduct_grid, [(0) x $conds_max];
    push @game_keys, $ascension->{'index'};
    foreach my $conduct (@{$ascension->{'conducts'}}) {
      my $cond_index = $conds_idx->{$conduct};
      $conduct_grid[$n_ascs][$cond_index] = 1;
    }
    $n_ascs += 1;
  }

  my @zscores, @sorted_keys = greedy_zscore(\@conduct_grid, $cond_multi_array, $conds_max, $n_ascs, \@game_keys);
  
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

    if ($game_index == $sorted_keys[$i]) {
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
    $inial_order) = @_;
  my @zfactors = (1) x $m_conds;
  my @zscores;
  my @final_order = @$initial_order;

  for (my $i = 0; $i < $n_ascs; $i++) {
    my $temp_best = 0;
    my $best_index = 0;
    for (my $j = $i; $j < $n_ascs; $j++) {
      # compute a trial conduct Z-score for each game, to see which is best
      # j loops through each game and i will steadily increase as we find best games
      my $score = 1;
      for (my $k = 0; $k < $m_conds; $k++) {
        if ($grid->[$i][$j] != 0) {
          $score *= $multipliers[$k];
        }
      }

      # is this the best score so far?
      if ($score > $temp_best) {
        $temp_best = $score;
        $best_index = $j;
      }
    }

    # now we should have the highest scoring game/index for the round
    if ($i != $best_index) {
      # swap the positions
      my $token = $final_order[$i];
      $final_order[$i] = $final_order[$best_index];
      $final_order[$best_index] = $token;
      for (my $k = 0; $k < $m_conds; $k++) {
        my $tmp = $grid->[$i][$k];
        $grid->[$i][$k] = $grid->[$best_index][$k];
        $grid->[$best_index][$k] = $tmp;
      }
    }

    # now we use whichever one is in position $i to update the z factors
    $score = 1;
    for (my $k = 0; $k < $m_conds; $k++) {
      if ($grid->[$i][$k] != 0) {
        $grid->[$i][$k] *= $zfactors[$k];
        $score *= $grid->[$i][$k] * $multipliers->[$k];
        $zfactors[$k] = 1/(1/$zfactors[$k] + 1);
      }
    }
    push @zscores, $score;
  }

  # i think i also want to return some information about how the
  # games have been (re)ordered
  return @zscores, @final_order;
}


sub finish
{
}



#=============================================================================

1;
