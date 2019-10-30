#!/usr/bin/env perl

#=============================================================================
# Object representing single player.
#=============================================================================

package TNNT::Player;

use Moo;
use TNNT::ClanList;
use TNNT::StreakList;
use TNNT::Config;


with 'TNNT::GameList::AddGame';
with 'TNNT::AscensionList';
with 'TNNT::ScoringList';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  required => 1
);

# clan instance reference or undef

has clan => (
  is => 'ro',
  builder => 1,
  lazy => 1,
);

has achievements => (
  is => 'rwp',
  default => sub { [] },
);

has achievements_hash => (
  is => 'rwp',
  default => sub { {} },
);

has maxcond => (
  is => 'rwp',
);

has maxach => (
  is => 'rwp',
);

has maxlvl => (
  is => 'rwp',
);

# this is filled in later from GameList's export() method

has rank => (
  is => 'rw',
);

# list of streaks, this is not TNNT::StreakList, however, to avoid bringing
# in all the streak-tracking machinery

has streaks => (
  is => 'rw',
  default => sub { [] },
);

# scummed games counter

has scum => (
  is => 'rwp',
  default => 0,
);

# lowest turncount win

has minturns => (
  is => 'rwp',
);

# minscore win

has minscore => (
  is => 'rwp',
);

# highscore win

has highscore => (
  is => 'rwp',
);

# fastest gametime

has realtime => (
  is => 'rwp',
);

has realtime_fmt => (
  is => 'rwp',
);


#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Builder for the 'clan' attribute
#-----------------------------------------------------------------------------

sub _build_clan
{
  my ($self) = @_;

  my $clans = TNNT::ClanList->instance();
  return $clans->get_by_player($self);
}


#-----------------------------------------------------------------------------
# Display player name (for development purposes).
#-----------------------------------------------------------------------------

sub disp
{
  my ($self) = @_;

  print $self->name(), "\n";
}


#-----------------------------------------------------------------------------
# This is implemented in GameList role.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;

  #--- track highest number of conducts

  if($game->is_ascended && $game->conducts() > ($self->maxcond() // 0)) {
    $self->_set_maxcond(scalar($game->conducts()));
  }

  #--- track highest number of achievements

  if(@{$game->achievements} > ($self->maxach() // 0)) {
    $self->_set_maxach(scalar(@{$game->achievements}));
  }

  #--- track maximum depth reached

  if($game->maxlvl() > ($self->maxlvl() // 0)) {
    $self->_set_maxlvl($game->maxlvl());
  }

  #--- track lowest turncount win

  if(
    $game->is_ascended()
    && (
      !defined $self->minturns()
      || $game->turns() < ($self->minturns())
    )
  ) {
    $self->_set_minturns($game->turns());
  }

  #--- track lowest score win

  if(
    $game->is_ascended()
    && (
      !defined $self->minscore()
      || $game->points() < $self->minscore()
    )
  ) {
    $self->_set_minscore($game->points());
  }

  #--- track highest score win

  if(
    $game->is_ascended()
    && (
      !defined $self->highscore()
      || $game->points() > $self->highscore()
    )
  ) {
    $self->_set_highscore($game->points());
  }

  #--- track fastest gametime win

  if(
    $game->is_ascended()
    && (
      !defined $self->realtime()
      || $game->realtime() < $self->realtime()
    )
  ) {
    $self->_set_realtime($game->realtime());
    $self->_set_realtime_fmt($game->_format_duration());
  }

  #--- keep counter of scummed games

  if($game->is_scummed()) {
    $self->_set_scum($self->scum() + 1);
  }
}


#-----------------------------------------------------------------------------
# Get the length of player's longest streak or undef.
#-----------------------------------------------------------------------------

sub _get_maxstreak_length
{
  my ($self) = @_;
  my $streaks = $self->streaks();

  my ($longest_streak) = sort {
     $b->count_games() <=> $a->count_games()
   } @{$streaks};

  if($longest_streak) {
    return $longest_streak->count_games();
  } else {
    return undef;
  }
}


#-----------------------------------------------------------------------------
# Export data
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;

  my %d = (
    name         => $self->name(),
    games        => $self->export_games(),
    achievements => $self->achievements(),
    scores       => $self->export_scores(),
    score        => $self->sum_score(),
    maxlvl       => $self->maxlvl(),
    rank         => $self->rank(),
    scum         => $self->scum(),
  );

  if($self->clan()) {
    $d{'clan'} = $self->clan()->n();
  }

  if(defined $self->maxcond()) {
    $d{'maxcond'} = $self->maxcond();
  }

  if(defined $self->maxach()) {
    $d{'maxach'} = $self->maxach();
  }

  if(defined $self->minturns()) {
    $d{'minturns'} = $self->minturns();
  }

  if(defined $self->minscore()) {
    $d{'minscore'} = $self->minscore();
  }

  if(defined $self->highscore()) {
    $d{'highscore'} = $self->highscore();
  }

  $d{'maxstreaklen'} = $self->_get_maxstreak_length();
  if(!defined $d{'maxstreaklen'}) {
    delete $d{'maxstreaklen'};
  }

  if($self->count_ascensions()) {
    $d{'ascs'} = $self->export_ascensions(),
    $d{'ratio'} = sprintf("%3.1f",
      $self->count_ascensions() / $self->count_games() * 100
    ),
  }

  if(@{$self->streaks()}) {
    $d{'streaks'} = [ map { $_->export_games() } @{$self->streaks()} ]
  }

  if(defined $self->realtime()) {
    $d{'realtime'} = $self->realtime_fmt();
  }

  #--- trophies (selected trophies for showcasing on the player page)

  my @trophies;
  my $cfg = TNNT::Config->instance()->config();

  my @trophy_names = qw(
    firstasc mostasc mostcond mostach lowscore highscore minturns realtime
    rsimpossible gimpossible maxstreak allroles allraces allaligns allgenders
    allconducts allachieve noscum
  );

  for my $race (qw(hum elf dwa gno orc)) {
    push(@trophy_names, "greatrace:$race", "lesserrace:$race");
  }

  for my $role (qw(arc bar cav hea mon pri ran rog val wiz)) {
    push(@trophy_names, "greatrole:$role", "lesserrole:$role");
  }

  for my $trophy (@trophy_names) {
    if(my $s = $self->get_score($trophy)) {
      push(@trophies, {
        'trophy' => $trophy,
        'title'  => $cfg->{'trophies'}{$trophy}{'title'},
        'when'   => $s->_format_when(),
      });
    }
  }

  $d{'trophies'} = \@trophies if @trophies;

  #--- finish

  return \%d;
}



#=============================================================================

1;
