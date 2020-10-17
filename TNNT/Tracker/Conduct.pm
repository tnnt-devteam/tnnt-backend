#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Conduct;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'conduct',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  #--- only ascended games

  return if !$game->is_ascended();

  #--- get summary score for conducts
  # The composite multiplier formula for all conducts is
  # multiplier₁ × multiplier₂ × … × multiplierₙ - 1

  my $cfg = TNNT::Config->instance()->config();
  my $multiplier = 1;
  print join ", ", $game->conducts_filtered();
  foreach my $conduct ($game->conducts_filtered()) {
    $multiplier *= $cfg->{'trophies'}{"conduct:$conduct"}{'multi'};
  }
  $multiplier--;

  #--- create scoring entry (only if there are any conducts)
  # note, that this is kind of 'degenerate' scoring entry, which is only used
  # to calculate ascension scoring entry; it has no 'points' and 'when' fields

  if($multiplier) {
    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      when => $game->endtime,
      points => 0,
      data => {
        conducts => [ $game->conducts() ],
        conducts_txt => join(' ', $game->conducts()),
        ncond => scalar($game->conducts()),
        multiplier => $multiplier,
      }
    );

    $game->add_score($se);
  }

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
