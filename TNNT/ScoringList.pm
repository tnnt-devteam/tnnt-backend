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
# Get sum of scores in a ScoringList. You can supply a list of filter strings
# to narrow down the score entries that are being summed. The list come in two
# modes:
#
# inclusive / only entries matching the filter strings are summed
# exclusive / only entries not matching any of the filter strings are summed
#
# exclusive filter is indicated by the first element having ! prepended to it.
#-----------------------------------------------------------------------------

sub sum_score
{
  my ($self, @filter) = @_;
  my @scores;

  #--- exclusive filter, indicated by the first element having prepended !

  if(@filter && substr($filter[0], 0, 0) eq '!') {
    @scores = grep {
      my $score = $_;
      grep { $score->{'trophy'} ne $_ } map { s/^!// } @filter;
    } @{$self->scores()};
  }

  #--- inclusive filter otherwise

  else {
    @scores = grep {
      my $score = $_;
      !@filter
      || grep { $score->{'trophy'} eq $_ } @filter;
    } @{$self->scores()};
  }

  #--- sum the selected entries

  my $sum = 0;
  for my $score (@scores) {
    $sum += $score->{'points'} // 0;
  }

  #--- finish

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
  }

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
