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

  my $full_set = $cfg->{'conducts'}{'order'};

  if (!%$tracker) {
    # initialise conduct grid tracking
    my $i = 0;
    foreach my $conduct (@$full_set) {
      $tracker->{'conduct_indices'}{$conduct} = $i;
      push @{$tracker->{'conduct_multipliers'}}, $cfg->{'trophies'}{"conduct:$conduct"}{'multi'};
      $i += 1;
    }
  }
  push @{$tracker->{'condascs'}}, { 'index' => $game->n(), 'conducts' => [$game->conducts()] };

  my $n_total_conducts = @$full_set;
  $tracker->{'conduct_grid'} = [];
  $tracker->{'Z_factor_array'} = [(1) x $n_total_conducts];
  $tracker->{'conduct_zscore'} = 0;

  dd(%$tracker);
  # fill an initial grid now, this will simply
  # contain 1 in each grid position with a conduct,
  # for the beginning
  my $i = 0;
  foreach my $ascension (@{$tracker->{'condascs'}}) {
    dd($ascension);
    push @{$tracker->{'conduct_grid'}}, (0) x $n_total_conducts;
    foreach my $conduct (@{$ascension->{'conducts'}}) {
      my $cond_index = int($tracker->{'conduct_indices'}{$conduct});
      $tracker->{'conduct_grid'}->[int($i)][$cond_index] = 1;
    }
    $i += 1;
  }

  $tracker->{'conduct_zscore'} = compute_best_zscore($tracker->{'conduct_grid'}, $tracker->{'Z_factor_array'},
                      $tracker->{'conduct_multipliers'}, scalar(@{$tracker->{'condascs'}}));

  #--- finish

  return $self;
}


sub compute_best_zscore {
  my ($grid, $zfactors, $multipliers, $n_ascs) = @_;
  my $n_conds = scalar(@$zfactors);

  my $zscore_cumulative = 0;
  for (my $i = 0; $i < $n_ascs; $i++) {
    my $temp_best = 0;
    my $best_index = 0;
    for (my $j = $i; $j < $n_ascs; $j++) {
      # compute a trial conduct Z-score for each game, to see which is best
      # j loops through each game and i will steadily increase as we find best games
      my $score = 50;
      for (my $k = 0; $k < $n_conds; $k++) {
        if ($grid->[$i][$j] != 0) {
          $score *= $multipliers->[$k];
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
      for (my $k = 0; $k < $n_conds; $k++) {
        my $tmp = $grid->[$i][$k];
        $grid->[$i][$k] = $grid->[$best_index][$k];
        $grid->[$best_index][$k] = $tmp;
      }
    }

    # now we use whichever one is in position $i to update the z factors
    my $round_score = 50;
    for (my $k = 0; $k < $n_conds; $k++) {
      if ($grid->[$i][$k] != 0) {
        $round_score *= $grid->[$i][$k] * $multipliers->[$k];
        $zfactors->[$k] = 1/(1/$zfactors->[$k] + 1);
      }
    }
    $zscore_cumulative += $round_score;
  }

  return $zscore_cumulative;
}


sub finish
{
}



#=============================================================================

1;
