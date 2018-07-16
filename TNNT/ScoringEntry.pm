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

# when was this trophy gained, this can be omitted when the gamelist is not
# empty as the highest 'endtime' value is used instead; generally most
# trophies will probably be given for finished games, so this is probably
# not needed

has when => (
  is => 'ro',
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



#=============================================================================

1;
