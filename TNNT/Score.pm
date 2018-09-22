#!/usr/bin/env perl

#=============================================================================
# This object handles ingesting the games from sources and compiling the
# scoreboard. This is a two-step process: 1. first you add all games by
# using the TNNT::Source's iterator; 2. run 'process' method that will compile
# the data.
#=============================================================================

package TNNT::Score;

use Carp;
use Moo;

use TNNT::Config;

with 'TNNT::GameList::AddGame';
with 'TNNT::AscensionList';
with 'TNNT::PlayerList';

use TNNT::Game;
use TNNT::TrackerList;
use TNNT::Tracker::Achievements;
use TNNT::Tracker::Ascension;
use TNNT::Tracker::Conduct;
use TNNT::Tracker::Speedrun;
use TNNT::Tracker::FirstAsc;
use TNNT::Tracker::MostAsc;
use TNNT::Tracker::MostCond;
use TNNT::Tracker::LowScore;
use TNNT::Tracker::HighScore;
use TNNT::Tracker::MinTurns;
use TNNT::Tracker::Streak;
use TNNT::Tracker::AllCats;
use TNNT::Tracker::ClanAscension;
use TNNT::Tracker::UniqueAscs;
use TNNT::Tracker::MostGames;
use TNNT::Tracker::AllCombos;
use TNNT::Tracker::GImpossible;
use TNNT::Tracker::GreatFoo;
use TNNT::Tracker::UniqueDeaths;
use TNNT::Tracker::MedusaCup;



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

  $tr->add_tracker(new TNNT::Tracker::Achievements);
  $tr->add_tracker(new TNNT::Tracker::Ascension);
  $tr->add_tracker(new TNNT::Tracker::Conduct);
  $tr->add_tracker(new TNNT::Tracker::Speedrun);
  $tr->add_tracker(new TNNT::Tracker::FirstAsc);
  $tr->add_tracker(new TNNT::Tracker::MostAsc);
  $tr->add_tracker(new TNNT::Tracker::MostCond);
  $tr->add_tracker(new TNNT::Tracker::LowScore);
  $tr->add_tracker(new TNNT::Tracker::HighScore);
  $tr->add_tracker(new TNNT::Tracker::MinTurns);
  $tr->add_tracker(new TNNT::Tracker::Streak);
  $tr->add_tracker(new TNNT::Tracker::AllCats);
  $tr->add_tracker(new TNNT::Tracker::ClanAscension);
  $tr->add_tracker(new TNNT::Tracker::UniqueAscs);
  $tr->add_tracker(new TNNT::Tracker::MostGames);
  $tr->add_tracker(new TNNT::Tracker::AllCombos);
  $tr->add_tracker(new TNNT::Tracker::GImpossible);
  $tr->add_tracker(new TNNT::Tracker::GreatFoo);
  $tr->add_tracker(new TNNT::Tracker::UniqueDeaths);
  # this needs to be the last tracker
  $tr->add_tracker(new TNNT::Tracker::MedusaCup);
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
  my $clans = TNNT::ClanList->instance();

  $clans->add_game($game);

  return $self;
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

  #--- invoke trackers' finish() method

  $tr->finish();

  #--- assign index numbers to the games

  $self->renumber();

  #--- set 'processed' attribute

  $self->_set_processed(1);
}


#-----------------------------------------------------------------------------
# Return all scoring data in single structure.
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;
  my $clans = TNNT::ClanList->instance();
  my $cfg = TNNT::Config->instance()->config();

  my %d = (
    config => $cfg,
    games => {
      all => $self->export_games(1),
      ascs => $self->export_ascensions(),
    },
    players => $self->export_players(),
    clans => $clans->export(),
  );

  return \%d;

}



#=============================================================================

1;
