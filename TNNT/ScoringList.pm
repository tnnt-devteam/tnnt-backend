#!/usr/bin/env perl

#=============================================================================
# Scoring list for players/clans. This is a collection of ScoringEntry
# objects and is used to hold scoring information for:
#
#  * players (Player class)
#  * games (Game class)
#  * clans (Clan class)
#=============================================================================

package TNNT::ScoringList;

use Moo::Role;
use List::Util qw(first);
use Data::Dump qw(dd);



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has scores => (
  is => 'rwp',
  default => sub { [] },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Add scoring entry, the entry should be a TNNT::ScoringEntry instance.
#-----------------------------------------------------------------------------

sub add_score
{
  my (
    $self,
    $entry,
  ) = @_;

  my $lst = $self->scores();
  push(@$lst, $entry);

  return $self;
}


#-----------------------------------------------------------------------------
# Get scoring entry for specified trophy shortname.
#-----------------------------------------------------------------------------

sub get_score
{
  my (
    $self,
    $trophy,
  ) = @_;

  return first { $_->trophy() eq $trophy } @{$self->scores()};
}

#-----------------------------------------------------------------------------
# This method finds a scoring entry by searching for a key/value pair in the
# data hash associated with the entry.
#
# Returns either a ref to the scoring entry, or undef.
#-----------------------------------------------------------------------------

sub get_score_by_key
{
  my (
    $self,
    $key,
    $value
  ) = @_;
  my $scores = $self->scores();
  die "no value to test for $key\n" if !defined $value;

  for(my $i = 0; $i < @$scores; $i++) {
    next if
      !defined $scores->[$i]->get_data($key)
      || $scores->[$i]->get_data($key) ne $value;
    return $scores->[$i];
  }
  return undef;
}

#-----------------------------------------------------------------------------
# Return new list of ScoringEntry instances that is a subset of the original
# one created by filtering by supplied filter list. The list comes in two
# variants:
#
# inclusive / only entries matching the filter strings are summed
# exclusive / only entries not matching any of the filter strings are summed
#
# exclusive filter is indicated by the first element having ! prepended to it.
# If the filter is empty, original instance is returned instead.
#
# FIXME: It would be nice to return ScoringList instance, but since it is role
# this is not possible. For some reason, creating class with the role doesn't
# work either (it breaks the role when you use that class in it).
#-----------------------------------------------------------------------------

sub filter_score
{
  my ($self, @filter) = @_;
  my $result = [];

  #--- if filter is empty, return original instance

  if(!@filter) {
    $result = $self->scores();
  }

  #--- exclusive filter, indicated by the first element having prepended !

  elsif(@filter && substr($filter[0], 0, 1) eq '!') {
    do {
      push(@$result, $_);
    } for grep {
      my $score = $_;
      !grep { $score->trophy() eq $_ } map { s/^!//r } @filter;
    } @{$self->scores()};
  }

  #--- inclusive filter otherwise

  else {
    do {
      push(@$result, $_);
    } for grep {
      my $score = $_;
      grep { $score->trophy() eq $_ } @filter;
    } @{$self->scores()};
  }

  #--- finish

  return $result;
}


#-----------------------------------------------------------------------------
# Get sum of scores in a ScoringList. The optional filter term uses the
# filter_score() method semantics (see above).
#-----------------------------------------------------------------------------

sub sum_score
{
  my ($self, @filter) = @_;

  my $sl = $self->filter_score(@filter);

  my $sum = 0;
  foreach my $score (@$sl) {
    $sum += $score->get_points();
  }

  return $sum;
}


#-----------------------------------------------------------------------------
# Remove scoring entry by trophy name.
#-----------------------------------------------------------------------------

sub remove_score
{
  my (
    $self,
    $trophy,
  ) = @_;

  $self->_set_scores(
    [ grep { $_->trophy() ne $trophy } @{$self->scores()} ]
  );
}


#-----------------------------------------------------------------------------
# This method finds a scoring entry, removes it and adds a new one to the end
# of the list. The search is done by finding a key/value in 'data' attribute.
# It is up to an implementor to make that key/value pair unique. Only the
# first match is removed.
#-----------------------------------------------------------------------------

sub remove_and_add
{
  my ($self, $key, $value, $new_entry) = @_;
  my $scores = $self->scores();

  for(my $i = 0; $i < @$scores; $i++) {
    next if
      !defined $scores->[$i]->get_data($key)
      || $scores->[$i]->get_data($key) ne $value;
    splice(@$scores, $i, 1);
    push(@$scores, $new_entry);
    return $self;
  }
  dd($scores); exit (1);
  return $self;
}


#-----------------------------------------------------------------------------
# Display the scoring list (for development purposes only)
#-----------------------------------------------------------------------------

sub disp_scores
{
  my ($self, $cb) = @_;
  my $i = 1;

  printf "--- SCORING LIST -- %d entries ---\n", scalar(@{$self->scores()});
  my $scores = $self->scores();
  foreach (@$scores) {
    printf "%d. ", $i++; $_->disp();
    if($cb) {
      $cb->($_);
    }
  };
  print "--- END OF SCORING LIST ---\n";
}


#-----------------------------------------------------------------------------
# Export the scoring list
#-----------------------------------------------------------------------------

sub export_scores
{
  my ($self) = @_;
  my @d;

  foreach my $s (@{$self->scores()}) {
    push(@d, $s->export());
  }

  return \@d;
}



#=============================================================================

1;
