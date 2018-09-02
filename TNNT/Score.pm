#!/usr/bin/env perl

#=============================================================================
# This object handles ingesting the games from sources and compiling the
# scoreboard. This is a two-step process: 1. first you add all games by
# using the TNNT::Source's iterator; 2. run 'process' method that will compile
# the data.
#=============================================================================

package TNNT::Score;

use Moo;

with 'TNNT::GameList';
with 'TNNT::AscensionList';
with 'TNNT::PlayerList';

use TNNT::Game;
use TNNT::TrackerList;
use TNNT::Tracker::FirstAsc;
use TNNT::Tracker::MostAsc;
use TNNT::Tracker::MostCond;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has 'global_tracker' => (
  is => 'ro',
  default => sub { new TNNT::TrackerList },
);

has 'processed' => (
  is => 'rwp',
  default => 0,
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
  $tr->add_tracker(new TNNT::Tracker::MostAsc);
  $tr->add_tracker(new TNNT::Tracker::MostCond);
}



#=============================================================================
#=== PUBLIC METHODS ==========================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Ingest a new game.
#-----------------------------------------------------------------------------

sub add_game
{
  # not implemented yet
};


#-----------------------------------------------------------------------------
# Process loaded games
#-----------------------------------------------------------------------------

sub process
{
  my $self = shift;
  my $tr = $self->global_tracker();

  #--- do this only once

  return if $self->processed();

  #--- process every game sequentially

  $self->iter_games(sub {
    my ($game) = @_;
    $tr->track_game($game);
  });

  #--- set 'processed' attribute

  $self->_set_processed(1);
}



#=============================================================================

1;
