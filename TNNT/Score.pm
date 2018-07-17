#!/usr/bin/env perl

#=============================================================================
# This object handles ingesting the games from sources and compiling the
# scoreboard
#=============================================================================

package TNNT::Score;

use Moo;

with 'TNNT::GameList';
with 'TNNT::AscensionList';
with 'TNNT::PlayerList';

use TNNT::Game;
use TNNT::TrackerList;
use TNNT::Tracker::FirstAsc;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has 'global_tracker' => (
  is => 'ro',
  default => sub { new TNNT::TrackerList },
);



#=============================================================================
#=== BUILD ===================================================================
#=============================================================================

sub BUILD
{
  my ($self) = @_;
  my $tr = $self->global_tracker();

  #--- register trackers

  $tr->add_tracker(new TNNT::Tracker::FirstAsc);
}



#=============================================================================
#=== PUBLIC METHODS ==========================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Ingest a new game.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $tr = $self->global_tracker();

  #--- get player

  my $player_name = $game->name();
  my $player = $self->get_player($player_name);

  #--- process the game

  $tr->track_game($game, $player);
};



#=============================================================================

1;
