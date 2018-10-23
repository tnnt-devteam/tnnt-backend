#!/usr/bin/env perl

#=============================================================================
# Tracker for speedrun ascensions.
#=============================================================================

package TNNT::Tracker::Speedrun;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'speedrun',
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

  #--- compute speedrunning bonus

  my $cfg = TNNT::Config->instance()->config();
  my $bonus = 0;
  if(
    !$cfg->{'trophies'}{'speedrun'}{'cutoff'}
    || $cfg->{'trophies'}{'speedrun'}{'cutoff'} >= $game->turns()
  ) {
    $bonus = int( $cfg->{'trophies'}{'speedrun'}{'factor'} / $game->turns() );
  }

  #--- create scoring entry

  if($bonus) {
    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games => [ $game ],
      when => $game->endtime(),
      points => $bonus,
    );

    $game->player()->add_score($se);
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
