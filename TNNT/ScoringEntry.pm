#!/usr/bin/env perl

#=============================================================================
# Scoring entry for single trophy.
#=============================================================================

package TNNT::ScoringEntry;

use Moo;
with 'TNNT::GameList';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# trophy shortname, if not defined in the config, the instantiation fails

has trophy => (
  is => 'ro',
  required => 1,
);

# points received for the entry, this will get automatically pulled from the
# configuration, no need to specify this

has points => (
  is => 'rwp',
  default => sub {},
);

# when was the scoring entry achieved; this is the endtime of the last game
# at the time this entry was created; this is not necessarily the endtime
# of the last game (the player can achieve the trophy, then add new games to
# it)

has when => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#=============================================================================
# Validate the trophy name and retrieve points (both using configuration).
#=============================================================================

sub BUILD
{
  my ($self, $args) = @_;

  my $trophy = $args->{'trophy'};
  my $cfg = TNNT::Config->instance()->config();

  if(!exists $cfg->{'trophies'}{$trophy}) {
    die "Trophy '$trophy' is not defined";
  }

  $self->_set_points(
    $cfg->{'trophies'}{$trophy}{'points'}
  );
}



#=============================================================================
# Empty function so that we can use TNNT::GameList
#=============================================================================

sub add_game
{
}


#=============================================================================
# Get the endtime of the last game in
#=============================================================================

sub timeref
{
  my ($self) = @_;

  if($self->games()->count()) {
    return $self->games()->last()->endtime();
  } else {
    return $self->when();
  }
}


#-----------------------------------------------------------------------------
# Display single scoring entry (for development purposes only)
#-----------------------------------------------------------------------------

sub disp
{
  my ($self) = @_;

  printf(
    "trophy=%s, points=%d, when=%s\n",
    $self->trophy(),
    $self->points(),
    scalar(gmtime($self->when()))
  );
}



#=============================================================================

1;
