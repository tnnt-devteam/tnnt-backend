#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Never Scum a Game" trophy. This trophy is given to a player
# on the first game (if it passes the no-scum criteria) and it is permanently
# removed from them when they first play a scummed game.
#=============================================================================

package TNNT::Tracker::NoScumming;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'noscum',
);

# player tracking hash, the keys are player names; three player states are
# distinguished:
#
# a) the player does not exist in the hash => the player's game was not yet
#    encountered
# b) the player exists in the hash, but the value is undef => the player's game
#    was encountered, but they have they "never scummed" conduct intact
# c) the player exists in the hash and the value is Game instance ref =>
#    the player has broken his conduct

has player_track => (
  is => 'ro',
  default => sub { {}; },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player_name = $game->name();
  my $player = $game->player();
  my $trk = $self->player_track();

  #--- do nothing if the player has already broken their conduct

  return $self if(
    exists $trk->{$player_name}
    && ref($trk->{$player_name})
  );

  #--- the player's game is encountered for the first time, create a scoring
  #--- entry for the trophy

  if(!exists $trk->{$player_name}) {

    # create scoring entry only if the game is not scummed
    if(!$game->is_scummed()) {
      $trk->{$player_name} = undef;
      $player->add_score(TNNT::ScoringEntry->new(
        trophy => $self->name(),
        when   => $game->endtime(),
      ));
    }

    # if the game is scummed, the player never earns the trophy to begin with
    else {
      $trk->{$player_name} = $game;
    }
  }

  #--- player already has the trophy, but has just scummed a game, remove his
  #--- trophy

  elsif(!$trk->{$player_name} && $game->is_scummed()) {
    $trk->{$player_name} = $game;
    $player->remove_score($self->name());
  }

  #--- finish

  return $self;
}


#-----------------------------------------------------------------------------
# Return list of player names of holders of the trophy.
#-----------------------------------------------------------------------------

sub holders
{
  my ($self) = @_;
  my $trk = $self->player_track();

  return [ grep { exists $trk->{$_} && !$trk->{$_} } keys %$trk ];
}


#-----------------------------------------------------------------------------
# Finish the tacking
#-----------------------------------------------------------------------------

sub finish
{
}


#=============================================================================

1;
