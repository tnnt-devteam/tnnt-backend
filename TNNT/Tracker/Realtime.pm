#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Fastest Realtime" trophy (both individual players and
# clans).
#=============================================================================

package TNNT::Tracker::Realtime;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'realtime',
);

has player => (
  is => 'rwp',
);

has clan => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);

has fastest_realtime => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clan = $player->clan();

  #--- count only ascending games

  return if !$game->is_ascended();

  #--- current game has the fastest realtime

  if(
    !defined $self->fastest_realtime()
    || $game->realtime() < $self->fastest_realtime()
  ) {

  #--- remove scoring entry from previous holder (if any)

    if($self->player()) {
      $self->player()->remove_score($self->name());
    }
    if($self->game()) {
      $self->game()->remove_score($self->name());
    }
    if($self->clan()) {
      $self->clan()->remove_score('clan-' . $self->name());
    }

  #--- set player and game

    $self->_set_game($game);
    $self->_set_player($game->player());
    $self->_set_clan($clan);

  #--- add scoring entry to new holder

    my $se_player = new TNNT::ScoringEntry(
      trophy => $self->name(),
      data   => { realtime => $game->realtime() },
      when   => $game->endtime(),
    );

    my $se_clan = new TNNT::ScoringEntry(
      trophy => 'clan-' . $self->name(),
      data   => { realtime => $game->realtime(), achiever => $game->name },
      when   => $game->endtime(),
    );

    $game->player()->add_score($se_player);
    $game->add_score($se_player);
    $clan->add_score($se_clan) if $clan;

  #--- store new max value

    $self->_set_fastest_realtime($game->realtime());

  }

}



sub finish
{
}



#=============================================================================

1;
