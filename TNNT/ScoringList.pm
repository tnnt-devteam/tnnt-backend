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
# Get sum of scores. You can supply list of scoring entry names to filter the
# entries with.
#-----------------------------------------------------------------------------

sub sum_score
{
  my $self = shift;
  my @filter = splice @_;

  #--- apply the filter

  my @scores = grep {
    my $score = $_;
    !@filter
    || grep { $score->{'trophy'} eq $_ } @filter;
  } @{$self->scores()};

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
# Display the scoring list (for development purposes only)
#-----------------------------------------------------------------------------

sub disp_scores
{
  my ($self) = @_;
  my $i = 1;

  printf "--- SCORING LIST -- %d entries ---\n", scalar(@{$self->scores()});
  my $scores = $self->scores();
  foreach (@$scores) { printf "%d. ", $i++; $_->disp() };
  print "--- END OF SCORING LIST ---\n";
}


#=============================================================================

1;
