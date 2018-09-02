#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Conducts in one Ascensions" trophy
#=============================================================================

package TNNT::Tracker::MostCond;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'mostcond',
);

has player => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);

has maxcond => (
  is => 'rwp',
  default => sub { 0 },
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

  if($game->conducts() > $self->maxcond()) {

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
      data   => { nconds => scalar($game->conducts()) },
      when   => $game->endtime(),
    ));

  #--- store new max value

    $self->_set_maxcond(scalar($game->conducts()));

  }

}



1;
