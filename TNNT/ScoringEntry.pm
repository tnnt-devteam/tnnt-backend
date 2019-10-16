#!/usr/bin/env perl

#=============================================================================
# Scoring entry for single trophy. ScoringList is used to manage lists of
# scoring entries.
#=============================================================================

package TNNT::ScoringEntry;

use Carp;
use Moo;
with 'TNNT::GameList::AddGame';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# trophy shortname, if not defined in the config, the instantiation fails;
# NOTE: naming this trophy is a bit of misnomer and should probably be changed
# to something clearer; not all scoring entries need to correspond with trophies
# users see; in particular 'conduct', 'speedrun' and 'streak' should only appear
# as entries attached to Game class instances and are used to calculate value
# of 'ascension' and 'clan-ascension' scoring entries

has trophy => (
  is => 'ro',
  required => 1,
);

# points received for the entry, this will get automatically pulled from the
# configuration, no need to specify this

has points => (
  is => 'rw',
);

# when was the scoring entry achieved; this is the endtime of the last game
# at the time this entry was created; this is not necessarily the endtime
# of the last game (the player can achieve the trophy, then add new games to
# it)

has when => (
  is => 'rwp',
  isa => sub {
    croak "ScoringEntry/when cannot be a reference" if ref $_[0];
  },
);

# additional, trophy-specific data

has data => (
  is => 'ro',
  default => sub { {}; },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Validate the trophy name and retrieve points (both using configuration).
# The point retrieval follows this semantics:
#
# If the trophy is found in the 'trophies' configuration section and the entry
# specifies points value, this value is used.
#
# If the trophy contains ':' (colon), and the 'trophies' configuration section
# contains entry for the part _before_ the colon, that point value is used.
# This allows to specify "default" point value for trophies with a subtype.
# For example "ach" is achievement trophy, but specific achievements are e.g.
# 'ach:meluckstone', 'ach:thebell' etc.
#-----------------------------------------------------------------------------

sub BUILD
{
  my ($self, $args) = @_;

  my $trophy = $args->{'trophy'};
  my $cfg = TNNT::Config->instance()->config();

  if(!defined $self->points()) {
    my $points = 0;

    # the trophy is directly defined in configuration
    if(
      exists $cfg->{'trophies'}{$trophy}
      && exists $cfg->{'trophies'}{$trophy}{'points'}
    ) {
      $points = $cfg->{'trophies'}{$trophy}{'points'}
    }

    # the trophy type is defined
    elsif(
      $trophy =~ /^([a-z-]+):/
      && exists $cfg->{'trophies'}{$1}
      && exists $cfg->{'trophies'}{$1}{'points'}
    ) {
      $points = $cfg->{'trophies'}{$1}{'points'}
    }

    # otherwise fail
    else {
      die "The trophy '$trophy' not defined in configuration";
    }

    $self->points($points);
  }
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
# Function to add hash entries into the "data" attribute. It takes key=>value
# pairs as argument.
#-----------------------------------------------------------------------------

sub add_data
{
  my ($self) = shift;
  my %new = @_;
  my $cur = $self->data();

  foreach my $key (keys %new) {
    $cur->{$key} = $new{$key};
  }

  return $self;
}


#-----------------------------------------------------------------------------
# Function to get hash entries from the "data" attribute.
#-----------------------------------------------------------------------------

sub get_data
{
  my ($self, $key) = @_;
  my $cur = $self->data();

  if(
    !$cur
    || !ref $cur
    || !exists $cur->{$key}
  ) {
    return undef;
  } else {
    return $cur->{$key};
  }
}


#-----------------------------------------------------------------------------
# Display single scoring entry (for development purposes only)
#-----------------------------------------------------------------------------

sub disp
{
  my ($self) = @_;

  printf(
    "trophy=%s, points=%d, when=%s, data={%s}\n",
    $self->trophy(),
    $self->points(),
    scalar(gmtime($self->when())),
    join(', ',
      map { $_ . '=' . $self->get_data($_) } (sort keys %{$self->data()})
    )
  );
}



#=============================================================================
# Get the 'when' attribute value; if the attribute's value is undefined and
# the list of games is defined in 'games' key, then this method tries to
# return endtime of the last game.
#=============================================================================

sub get_when
{
  my ($self) = @_;

  #--- if explicit 'when' is set, return that

  if(defined $self->when()) {
    return $self->when();
  }

  #--- otherwise find last game's endtime (we're assuming the list
  #--- of games is ordered)

  elsif($self->games()) {
    my $games = $self->dgames();
    return $games->[ scalar(@$games) -1 ]->endtime();
  }

  #--- fail with undef

  return undef;
}


#=============================================================================
# Get the 'points' attribute value; if the value is undefined and list of
# games is present in 'games' attribute, then sum all the games' scoring
# entries' 'points' values and return that instead.
#=============================================================================

sub get_points
{
  my ($self) = @_;

  #--- if 'points' value is defined, return that

  if(defined $self->points()) {
    return $self->points();
  }

  #--- otherwise sum game list scoring entries

  elsif($self->games()) {
    my $games = $self->games();
    my $points = 0;
    foreach my $game (@$games) {
      $points += $game->sum_score();
    }
    return $points;
  }
}

#----------------------------------------------------------------------------
# Format the when field
#----------------------------------------------------------------------------

sub _format_when
{
  my ($self) = @_;

  my @t = gmtime($self->when());
  return sprintf("%04d-%02d-%02d %02d:%02d", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1]);
}


#-----------------------------------------------------------------------------
# Export data
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;

  return {
    trophy => $self->trophy(),
    points => $self->get_points(),
    when   => $self->get_when(),
    when_fmt => $self->_format_when(),
    data   => $self->data(),
  };
}



#=============================================================================

1;
