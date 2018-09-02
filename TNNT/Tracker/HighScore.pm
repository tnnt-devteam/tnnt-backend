#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Highest Score" trophy
#=============================================================================

package TNNT::Tracker::HighScore;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'highscore',
);

has player => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);

has max_score => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();

  #--- count only ascending games

  return if !$game->is_ascended();

  #--- current game has the most conducts so far

  if(
    !defined $self->max_score()
    || $game->points() > $self->max_score()
  ) {

  #--- remove scoring entry from previous holder (if any)

  if($self->player()) {
      $self->player()->remove_score($self->name());
    }

  #--- set player and game

    $self->_set_game($game);
    $self->_set_player($game->player());

  #--- add scoring entry to new holder

    $game->player()->add_score(new TNNT::ScoringEntry(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { score => $game->points() },
      when   => $game->endtime(),
    ));

  #--- store new max value

    $self->_set_max_score($game->points());

  }

}



1;
