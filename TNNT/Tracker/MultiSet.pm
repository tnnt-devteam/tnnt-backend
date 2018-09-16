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
# Tracking multiple values in one set is also possible:
#
#    $ms->track(set1 => [ 'value1', 'value2', ... ]
#
# This invocation returns true if all the values in all sets were tracked at
# least once. You can invoke the track() method without arguments, then it
# will just return the fullfillment status of the instance.
#
# If the last odd arguments to new_sets() is a coderef, then this is invoked
# when the state flips into fullfilled.
#
# The tracker has two modes: 'strict' will die on attempting to track a value
# that is not in the list of possible values; 'loose' mode will silently skip
# that value.
#=============================================================================

package TNNT::Tracker::MultiSet;

use Moo;
use Carp;



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

has _cb => (
  is => 'rwp',
  writer => '_set_cb',
);

has mode => (
  is => 'rw',
  default => 'strict',
  isa => sub {
    $_[0] =~ /^(strict|loose)$/ or die "Invalid mode '$_[0]' specified";
  }
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
  my ($self, @sets) = @_;
  my $cb;
  my %sets;

  if(@sets % 2) {
    $cb = pop @sets;
  }
  %sets = @sets;
  $self->new(_sets => \%sets, _cb => $cb);
}


#-----------------------------------------------------------------------------
# The tracking function. Returns true if the state of the instance is
# 'fullfilled'.
#-----------------------------------------------------------------------------

sub track
{
  my ($self, %args) = @_;

  return 1 if $self->_achieved();

  #--- mark all the values from arguments as seen

  foreach my $key (keys %args) {
    my @values = ref $args{$key} ? @{$args{$key}} : ($args{$key});
    foreach my $value (@values) {
      if(
        $self->mode() eq 'strict'
        && !exists $self->_trk()->{$key}->{$value}
      ) {
        croak "MultiSet: Invalid set '$key' element '$value'";
      }
      $self->_trk()->{$key}->{$value} = 1;
    }
  }

  #--- check whether all set elements were already seen

  my $achieve = 1;
  TRACK: foreach my $set (keys %{$self->_trk()}) {
    foreach my $key (keys %{$self->_trk()->{$set}}) {
      if(!$self->_trk()->{$set}->{$key}) {
        $achieve = 0;
        last TRACK;
      }
    }
  }

  #--- invoke callback if flipping into achieved state

  if($achieve && $self->_cb()) {
    $self->_cb()->();
    $self->_set_cb(undef);
  }

  #--- finish

  $self->_achieved($achieve);
  return $achieve;
}



#=============================================================================

1;
