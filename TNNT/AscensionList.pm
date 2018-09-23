#!/usr/bin/env perl

#=============================================================================
# Role extending TNNT::GameList role with a list of ascending games.
#=============================================================================


package TNNT::AscensionList;

use Tie::Array::Sorted;
use Moo::Role;

requires 'add_game';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has ascensions => (
  is => 'rw',
  default => sub {
    my @ar;
    tie @ar, 'Tie::Array::Sorted', sub {
      $_[0]->endtime() <=> $_[1]->endtime()
    };
    return \@ar;
  },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

around 'add_game' => sub {
  my ($orig, $self, $game) = splice(@_, 0, 3);

  if($game->is_ascended()) {
    push(@{$self->ascensions()}, $game);
  }

  return $orig->($self, $game, @_);
};


sub count_ascensions
{
  my ($self) = @_;

  my $al = $self->ascensions();
  return scalar(@$al);
}


sub iter_ascensions
{
  my ($self, $cb) = @_;

  foreach (@{$self->ascensions()}) {
    $cb->($_);
  }
}


#=============================================================================
# Return last game in the list. This is also the newest game, because the list
# is always sorted.
#=============================================================================

sub last_ascension
{
  my ($self) = @_;

  if($self->count_ascensions()) {
    return $self->ascensions()->[-1];
  } else {
    return ();
  }
}


#-----------------------------------------------------------------------------
# Return export data
#-----------------------------------------------------------------------------

sub export_ascensions
{
  my ($self) = @_;
  my $c = $self->count_ascensions();
  my @d;

  for(my $i = 0; $i < $c; $i++) {
    $d[$i] = $self->ascensions()->[$i]->n();
  }

  return \@d;
}



#=============================================================================

1;
