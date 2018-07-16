#!/usr/bin/env perl

#=============================================================================
# Object representing single game.
#=============================================================================

package TNNT::Game;

use Moo;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has role      => ( is => 'ro', required => 1 );
has race      => ( is => 'ro', required => 1 );
has gender    => ( is => 'ro', required => 1 );
has align     => ( is => 'ro', required => 1 );
has gender0   => ( is => 'ro', required => 1 );
has align0    => ( is => 'ro', required => 1 );
has name      => ( is => 'ro', required => 1 );
has death     => ( is => 'ro', required => 1 );
has conduct   => ( is => 'ro', required => 1 );
has turns     => ( is => 'ro', required => 1 );
has achieve   => ( is => 'ro', required => 1 );
has realtime  => ( is => 'ro', required => 1 );
has starttime => ( is => 'ro', required => 1 );
has endtime   => ( is => 'ro', required => 1 );
has points    => ( is => 'ro', required => 1 );
has deathlev  => ( is => 'ro', required => 1 );
has maxlvl    => ( is => 'ro', required => 1 );
has hp        => ( is => 'ro', required => 1 );
has maxhp     => ( is => 'ro', required => 1 );
has deaths    => ( is => 'ro', required => 1 );



#=============================================================================
#=============================================================================

sub is_ascended
{
  my ($self) = @_;

  return ($self->death() =~ /^ascended/);
}


#=============================================================================
# Display game on console (for development purposes only)
#=============================================================================

sub disp
{
  my ($self) = @_;

  printf(
    "%-16s  %s-%s-%s-%s  %s  %6d turns  %8d points\n",
    $self->name(),
    $self->role(), $self->race(), $self->gender0(), $self->align0(),
    scalar(gmtime($self->endtime())),
    $self->turns(), $self->points()
  );
}



#=============================================================================

1;
