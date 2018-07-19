#!/usr/bin/env perl

#=============================================================================
# Tracker for the "First Ascension" trophy
#=============================================================================

package TNNT::Tracker::FirstAsc;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'firstasc',
);

has player => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub process_game
{
  my (
    $self,
    $game,
    $player
  ) = @_;

  #--- if the game is ascended and its endtime is lower than the current's
  #--- first ascension's endtime, or there is not current ascension, record it

  if(
    $game->is_ascended()
    && (
      !$self->game()
      || $game->endtime() < $self->game()->endtime()
    )
  ) {

    #--- remove scoring entry from previous holder (if any)

    if($self->player()) {
      $self->player()->remove_score('firstasc');
    }

    #--- set player and game

    $self->_set_game($game);
    $self->_set_player($player);

    #--- add scoring entry to new holder

    $player->add_score(new TNNT::ScoringEntry(
      trophy => 'firstasc',
      games => [ $game ],
      when => $game->endtime(),
    ));
  }

  return $self;
}



#=============================================================================

1;
