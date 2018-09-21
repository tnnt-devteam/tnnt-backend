#!/usr/bin/env perl

#=============================================================================
# Object representing single player.
#=============================================================================

package TNNT::Player;

use Moo;
use TNNT::ClanList;

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

has maxlvl => (
  is => 'rwp',
);

# this is filled in later from GameList's export() method

has rank => (
  is => 'rw',
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
  return $clans->find_clan($self);
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

  #--- track maximum depth reached

  if($game->maxlvl() > ($self->maxlvl() // 0)) {
    $self->_set_maxlvl($game->maxlvl());
  }
}


#-----------------------------------------------------------------------------
# Export data
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;

  my %d = (
    name   => $self->name(),
    games  => $self->export_games(),
    ach    => $self->achievements(),
    scores => $self->export_scores(),
    score  => $self->sum_score(),
    maxlvl => $self->maxlvl(),
    rank   => $self->rank(),
  );

  if($self->clan()) {
    $d{'clan'} = $self->clan()->n();
  }

  if(defined $self->maxcond()) {
    $d{'maxcond'} = $self->maxcond();
  }

  if($self->count_ascensions()) {
    $d{'ascs'} = $self->export_ascensions(),
    $d{'ratio'} = sprintf("%3.1f",
      $self->count_ascensions() / $self->count_games() * 100
    ),
  }

  return \%d;
}



#=============================================================================

1;
