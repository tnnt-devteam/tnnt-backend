#!/usr/bin/env perl

#=============================================================================
# Clan class
#=============================================================================

package TNNT::Clan;

use Moo;
with 'TNNT::ScoringList';
with 'TNNT::GameList::AddGame';
with 'TNNT::AscensionList';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'rw',
  required => 1,
);

has n => (
  is => 'ro',
  required => 1,
);

has players => (
  is => 'rw',
  default => sub { []; }
);

has admins => (
  is => 'rw',
  default => sub { []; }
);

has achievements => (
  is => 'ro',
  default => sub { []; }
);

has unique_deaths => (
  is => 'ro',
  default => sub { []; }
);

has udeaths_rank => (
  is => 'rw',
  default => -1,
);


#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#=============================================================================
# Add player to the clan, used during reading the clans from database.
#=============================================================================

sub add_player
{
  my ($self, $player, $admin) = @_;

  push(@{$self->players()}, $player);
  push(@{$self->admins()}, $player) if $admin;

  return $self;
}



#=============================================================================
# Returns true if player name supplied in argument is a clan member.
#=============================================================================

sub is_member
{
  my ($self, $player) = @_;

  if(
    grep { $_ eq $player } @{$self->players()}
  ) {
    return 1;
  } else {
    return undef;
  }
}


#=============================================================================
# Returns true if player name supplied in argument is a clan admin.
#=============================================================================

sub is_admin
{
  my ($self, $player) = @_;

  if(
    grep { $_ eq $player } @{$self->admins()}
  ) {
    return 1;
  } else {
    return undef;
  }
}


#-----------------------------------------------------------------------------
# Empty but required for the GameList role.
#-----------------------------------------------------------------------------

sub add_game
{
}



#=============================================================================

1;
