#!/usr/bin/env perl

#=============================================================================
# Scoring entry for single trophy. ScoringList is used to manage lists of
# scoring entries.
#=============================================================================

package TNNT::ScoringEntry;

use Moo;
with 'TNNT::GameList::AddGame';



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
);

# when was the scoring entry achieved; this is the endtime of the last game
# at the time this entry was created; this is not necessarily the endtime
# of the last game (the player can achieve the trophy, then add new games to
# it)

has when => (
  is => 'rwp',
);

# additional, trophy-specific data

has data => (
  is => 'ro',
  default => sub { {}; },
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

  if(!defined $self->points()) {
    $self->_set_points(
      $cfg->{'trophies'}{$trophy}{'points'} // 0
    );
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



#=============================================================================

1;
