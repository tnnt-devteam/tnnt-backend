#!/usr/bin/env perl

#=============================================================================
# Role encapsulating plain list of games (ie. array of TNNT::Game objects).
#=============================================================================


package TNNT::GameList;

use Tie::Array::Sorted;
use Moo::Role;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# list of games; by default we use Tie::Array::Sorted to keep this list
# permanently sorted; if this is not needed, then just supply your own
# arrayref on instantiation

has games => (
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

sub count_games
{
  my ($self) = @_;

  my $gl = $self->games();
  return scalar(@$gl);
}


sub iter_games
{
  my ($self, $cb) = @_;

  foreach (@{$self->games()}) {
    $cb->($_);
  }
}


#=============================================================================
# Return last game in the list. This is also the newest game, because the list
# is always sorted.
#=============================================================================

sub last_game
{
  my ($self) = @_;

  if($self->count_games()) {
    return $self->games()->[-1];
  } else {
    return ();
  }
}



#=============================================================================

1;
