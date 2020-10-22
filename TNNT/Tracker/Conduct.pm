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

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;
  my $cfg = TNNT::Config->instance()->config();
  my @conducts = $game->conducts();
  #--- only ascended games
  if (!$game->is_ascended()) {
    return;
  }

  my @conducts = $game->conducts();
  my $multiplier = 1;
  foreach my $conduct (@conducts) {
    $multiplier *= $cfg->{'trophies'}{"conduct:$conduct"}{'multi'};
  }

  my $se = new TNNT::ScoringEntry(
    trophy => $self->name(),
    when => $game->endtime,
    points => 0,
    data => {
      conducts => [ $game->conducts() ],
      conducts_txt => join(' ', $game->conducts()),
      ncond => scalar($game->conducts()),
      multiplier => $zscores[$i],
    }
  );
  $game->add_score($se);
  #--- finish

  return $self;
}

sub finish
{
}



#=============================================================================

1;
