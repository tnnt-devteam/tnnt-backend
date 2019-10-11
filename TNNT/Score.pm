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
use TNNT::Tracker::Realtime;
use TNNT::Tracker::Streak;
use TNNT::Tracker::AllCats;
use TNNT::Tracker::UniqueAscs;
use TNNT::Tracker::MostGames;
use TNNT::Tracker::AllCombos;
use TNNT::Tracker::RSImpossible;
use TNNT::Tracker::GImpossible;
use TNNT::Tracker::GreatFoo;
use TNNT::Tracker::UniqueDeaths;
use TNNT::Tracker::NoScumming;
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
  # following trackers create data for scoring ascensions and must run before
  # the Ascension tracker
  $tr->add_tracker(new TNNT::Tracker::Conduct);
  $tr->add_tracker(new TNNT::Tracker::Speedrun);
  $tr->add_tracker(new TNNT::Tracker::Streak);
  # Ascension tracker uses data from the above trackers
  $tr->add_tracker(new TNNT::Tracker::Ascension);
  $tr->add_tracker(new TNNT::Tracker::FirstAsc);
  $tr->add_tracker(new TNNT::Tracker::MostAsc);
  $tr->add_tracker(new TNNT::Tracker::MostCond);
  $tr->add_tracker(new TNNT::Tracker::LowScore);
  $tr->add_tracker(new TNNT::Tracker::HighScore);
  $tr->add_tracker(new TNNT::Tracker::MinTurns);
  $tr->add_tracker(new TNNT::Tracker::Realtime);
  $tr->add_tracker(new TNNT::Tracker::AllCats);
  # superseded by new Ascension tracker
  $tr->add_tracker(new TNNT::Tracker::UniqueAscs);
  $tr->add_tracker(new TNNT::Tracker::MostGames);
  $tr->add_tracker(new TNNT::Tracker::AllCombos);
  $tr->add_tracker(new TNNT::Tracker::RSImpossible);
  $tr->add_tracker(new TNNT::Tracker::GImpossible);
  $tr->add_tracker(new TNNT::Tracker::GreatFoo);
  $tr->add_tracker(new TNNT::Tracker::UniqueDeaths);
  $tr->add_tracker(new TNNT::Tracker::NoScumming);
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
  my $cfg = TNNT::Config->instance();

  my %d = (
    config => $cfg->config(),
    games => {
      all => $self->export_games(1),
      ascs => $self->export_ascensions(),
    },
    players => $self->export_players(),
    clans => $clans->export(),
  );

  $d{'config'}{'achievements-ordered'} = $cfg->order_achievements();

  #--- trophies

  my $tr = $self->global_tracker();

  # First Ascension

  if(defined $tr->get_tracker_by_name('firstasc')->player()) {
    $d{'trophies'}{'players'}{'firstasc'}
    = $tr->get_tracker_by_name('firstasc')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('firstasc')->clan()) {
    $d{'trophies'}{'clans'}{'firstasc'}
    = $tr->get_tracker_by_name('firstasc')->clan()->n();
  }

  # Most Ascensions

  if(defined $tr->get_tracker_by_name('mostasc')->player()) {
    $d{'trophies'}{'players'}{'mostasc'}
    = $tr->get_tracker_by_name('mostasc')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('mostasc')->clan()) {
    $d{'trophies'}{'clans'}{'mostasc'}
    = $tr->get_tracker_by_name('mostasc')->clan()->n();
  }

  # Lowest Turncount

  if(defined $tr->get_tracker_by_name('minturns')->player()) {
    $d{'trophies'}{'players'}{'minturns'}
    = $tr->get_tracker_by_name('minturns')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('minturns')->clan()) {
    $d{'trophies'}{'clans'}{'minturns'}
    = $tr->get_tracker_by_name('minturns')->clan()->n();
  }

  # Fastest Realtime

  if(defined $tr->get_tracker_by_name('realtime')->player()) {
    $d{'trophies'}{'players'}{'realtime'}
    = $tr->get_tracker_by_name('realtime')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('realtime')->clan()) {
    $d{'trophies'}{'clans'}{'realtime'}
    = $tr->get_tracker_by_name('realtime')->clan()->n();
  }

  # Most Conducts in single game

  if(defined $tr->get_tracker_by_name('mostcond')->player()) {
    $d{'trophies'}{'players'}{'mostcond'}
    = $tr->get_tracker_by_name('mostcond')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('mostcond')->clan()) {
    $d{'trophies'}{'clans'}{'mostcond'}
    = $tr->get_tracker_by_name('mostcond')->clan()->n();
  }

  # Lowest Score

  if(defined $tr->get_tracker_by_name('lowscore')->player()) {
    $d{'trophies'}{'players'}{'lowscore'}
    = $tr->get_tracker_by_name('lowscore')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('lowscore')->clan()) {
    $d{'trophies'}{'clans'}{'lowscore'}
    = $tr->get_tracker_by_name('lowscore')->clan()->n();
  }

  # Highest Score

  if(defined $tr->get_tracker_by_name('highscore')->player()) {
    $d{'trophies'}{'players'}{'highscore'}
    = $tr->get_tracker_by_name('highscore')->player()->name();
  }

  if(defined $tr->get_tracker_by_name('highscore')->clan()) {
    $d{'trophies'}{'clans'}{'highscore'}
    = $tr->get_tracker_by_name('highscore')->clan()->n();
  }

  # Longest Streak

  my $maxstreak = $tr->get_tracker_by_name('streak')->maxstreak();

  if(defined $maxstreak) {

    $d{'trophies'}{'players'}{'maxstreak'}
    = $maxstreak->last_game()->player()->name();

    if(defined $maxstreak->last_game()->player()->clan()) {
      $d{'trophies'}{'clans'}{'maxstreak'}
      = $maxstreak->last_game()->player()->clan()->n()
    }
  }

  # All Roles/Races/Genders/Alignments/Conducts

  my $allcats = $tr->get_tracker_by_name('allcats');

  for my $cat (qw(allroles allraces allgenders allaligns allconducts)) {
    if(@{$allcats->players()->{$cat}}) {
      $d{'trophies'}{'players'}{$cat}
      = [ map { $_->name() } @{$allcats->players()->{$cat}} ];
    }

    if(@{$allcats->clans()->{$cat}}) {
      $d{'trophies'}{'clans'}{$cat}
      = [ map { $_->n() } @{$allcats->clans()->{$cat}} ];
    }
  }

  # All Achievements

  my $achieve_tr = $tr->get_tracker_by_name('achievements');

  if(@{$achieve_tr->players_track()}) {
    $d{'trophies'}{'players'}{'allachieve'} = $achieve_tr->players_track();
  }

  if(@{$achieve_tr->clans_track()}) {
    $d{'trophies'}{'clans'}{'allachieve'} = $achieve_tr->clans_track();
  }

  # The Respectably-Sized Impossible

  my $achieve_rsi = $tr->get_tracker_by_name('rsimpossible');

  if(@{$achieve_rsi->players()}) {
    $d{'trophies'}{'players'}{'rsimpossible'} = $achieve_rsi->players();
  }

  if(@{$achieve_rsi->clans()}) {
    $d{'trophies'}{'clans'}{'rsimpossible'} = $achieve_rsi->clans();
  }

  # The Great Impossible

  my $achieve_gi = $tr->get_tracker_by_name('gimpossible');

  if(@{$achieve_gi->players()}) {
    $d{'trophies'}{'players'}{'gimpossible'} = $achieve_gi->players();
  }

  if(@{$achieve_gi->clans()}) {
    $d{'trophies'}{'clans'}{'gimpossible'} = $achieve_gi->clans();
  }

  # Great/Lesser Foo

  my $greatfoo = $tr->get_tracker_by_name('greatfoo');

  (
    $d{'trophies'}{'players'}{'greatfoo'},
    $d{'trophies'}{'clans'}{'greatfoo'}
  ) = $greatfoo->export();

  # Unique Deaths

  my $uqdeath_tr = $tr->get_tracker_by_name('uniquedeaths');
  if(defined $uqdeath_tr->topclan()) {
    $d{'trophies'}{'clans'}{'uniquedeaths'} = $uqdeath_tr->topclan()->n();
  }

  # Most Unique Ascensions

  my $uniqascs_tr = $tr->get_tracker_by_name('clan-uniqascs');
  if(defined $uniqascs_tr->topclan()) {
    $d{'trophies'}{'clans'}{'uniqascs'} = $uniqascs_tr->topclan()->n();
  }

  # Most Games Over 1000 turns

  my $mostgames_tr = $tr->get_tracker_by_name('clan-mostgames');
  if(defined $mostgames_tr->topclan()) {
    $d{'trophies'}{'clans'}{'mostgames'} = $mostgames_tr->topclan()->n();
  }

  # Master and Dominator

  my $allcombos_tr = $tr->get_tracker_by_name('clan-allcombos');
  $d{'trophies'}{'clans'}{'master'} = $allcombos_tr->masters();
  $d{'trophies'}{'clans'}{'dominator'} = $allcombos_tr->dominators();

  # Medusa Cup

  my $medusacup_tr = $tr->get_tracker_by_name('clan-medusacup');
  if(defined $medusacup_tr->topclan()) {
    $d{'trophies'}{'clans'}{'medusacup'} = $medusacup_tr->topclan()->n();
  }

  # Never Scum a Game

  my $noscum_tr = $tr->get_tracker_by_name('noscum');
  my $noscum_holders = $noscum_tr->holders();
  if(@$noscum_holders) {
    $d{'trophies'}{'players'}{'noscum'} = $noscum_holders;
  }

  #--- finish

  return \%d;

}



#=============================================================================

1;
