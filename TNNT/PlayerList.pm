#!/usr/bin/env perl

#=============================================================================
# Object representing list of players.
#=============================================================================

package TNNT::PlayerList;

use TNNT::Player;
use Moo::Role;

requires 'add_game';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has players => (
  is => 'rw',
  default => sub { {}; },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Get player by name.
#-----------------------------------------------------------------------------

sub get_player
{
  my ($self, $name) = @_;
  my $pl = $self->players();

  if(exists $pl->{$name}) {
    return $pl->{$name};
  } else {
    return undef;
  }
}


#-----------------------------------------------------------------------------
# Return number of players.
#-----------------------------------------------------------------------------

sub count_players
{
  my ($self) = @_;

  my $pl = $self->players();
  return scalar(keys %$pl);
}


#-----------------------------------------------------------------------------
# Player iterator.
#-----------------------------------------------------------------------------

sub iter_players
{
  my ($self, $cb) = @_;

  my $players = $self->players();

  foreach my $player_name (keys %$players) {
    my $player = $self->players()->{$player_name};
    $cb->($player);
  }
}


#-----------------------------------------------------------------------------
# Handle new game, if player doesn't exist, add them to the list.
#-----------------------------------------------------------------------------

around 'add_game' => sub {

  my (
    $orig,
    $self,
    $game,
  ) = @_;

  my $pl = $self->players();
  my $plr_name = $game->name();

  #--- player already in the player list, just add the game to their list

  if(exists $pl->{$plr_name}) {
    $pl->{$plr_name}->add_game($game);
    $game->player($pl->{$plr_name});
  }

  #--- player not in the player list, create new instance

  else {
    my $player = $pl->{$plr_name} = new TNNT::Player(
      name => $plr_name,
    );
    $player->add_game($game);
    $game->player($player);
  }

  #--- return the player object

  return $orig->($self, $game);
};



#=============================================================================

1;
