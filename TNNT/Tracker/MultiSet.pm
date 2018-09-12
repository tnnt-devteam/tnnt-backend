#!/usr/bin/env perl

#=============================================================================
# Generic utility class for tracking achievements. This is how it works:
#
# The class is instantiated with one or more tagged sets:
#
#    $ms = MultiSet->new_sets(set1 => \@set1, set2 => \@set2, ...)
#
# The 'set1', 'set2' are names or tags. The sets must have at least one
# element. Once initialized, tracking is performed by invoking the 'track'
# method with tag/value pairs. Multiple pairs can be tracked with one
# invocation
#
#    $ms->track(set1 => 'value1', ...)
#
# This invocation returns true if all the values in all sets were tracked at
# least once. You can invoke the track() method without arguments, then it
# will just return the fullfillment status of the instance.
#=============================================================================

package TNNT::Tracker::MultiSet;

use Moo;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has _sets => (
  is => 'rw',
  default => sub { {} },
);

has _trk => (
  is => 'rw',
  builder => '_build_trk',
);

has _achieved => (
  is => 'rw',
  default => 0,
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Builder function that converts the arrays representing the sets into hashes
# for easy access.
#-----------------------------------------------------------------------------

sub _build_trk
{
  my ($self) = @_;
  my %re;

  foreach my $set (keys %{$self->_sets()}) {
    foreach my $el (@{$self->_sets()->{$set}}) {
      $re{$set}{$el} = 0;
    }
  }

  return \%re;
}


#-----------------------------------------------------------------------------
# This is function to instantiate the class. It is separate from new in order
# to make sets specification slightly less verbose.
#-----------------------------------------------------------------------------

sub new_sets
{
  my ($self, %sets) = @_;

  $self->new(_sets => \%sets);
}


#-----------------------------------------------------------------------------
# The tracking function. Returns true if the state of the instance is
# 'fullfilled'.
#-----------------------------------------------------------------------------

sub track
{
  my ($self, %args) = @_;

  return 1 if $self->_achieved();

  foreach my $key (keys %args) {
    die if !exists $self->_trk()->{$key}->{$args{$key}};
    $self->_trk()->{$key}->{$args{$key}} = 1;
  }

  my $achieve = 1;
  TRACK: foreach my $set (keys %{$self->_trk()}) {
    foreach my $key (keys %{$self->_trk()->{$set}}) {
      if(!$self->_trk()->{$set}->{$key}) {
        $achieve = 0;
        last TRACK;
      }
    }
  }

  $self->_achieved($achieve);
  return $achieve;
}



#=============================================================================

1;
