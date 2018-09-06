#!/usr/bin/env perl

#=============================================================================
# Tracker for single ascensions.
#=============================================================================

package TNNT::Tracker::Ascension;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'ascension',
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

  #--- create scoring entry

  my $se = new TNNT::ScoringEntry(
    trophy => $self->name(),
    games => [ $game ],
    when => $game->endtime(),
  );

  $game->player()->add_score($se);
  $game->add_score($se);

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
