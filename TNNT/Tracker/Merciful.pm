#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Merciful;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'merciful',
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

  my $cfg = TNNT::Config->instance()->config();
  my $player = $game->player;
  my $clan = $player->clan;
  for my $entity ($player, $clan) {
    foreach my $mercy ($game->mercifulness()) {
      #--- check if player already has this trophy, then
      # add scoring entry for that
      next if !$entity;

      if(! $entity->get_score("mercy:$mercy")) {
        my $se = new TNNT::ScoringEntry(
          trophy => "mercy:$mercy",
          when => $game->endtime(),
          game => [ $game ]
        );

        $entity->add_score($se);
      }
  }

  
  }

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
