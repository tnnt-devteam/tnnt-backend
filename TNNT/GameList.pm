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


#-----------------------------------------------------------------------------
# Update the index numbers (the 'n') attribute of the Game class. This number
# is used to reference the game in the exported data structure.
#-----------------------------------------------------------------------------

sub renumber
{
  my ($self) = @_;
  my $c = $self->count_games();

  for(my $i = 0; $i < $c; $i++) {
    $self->games()->[$i]->{'n'} = $i;
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


#-----------------------------------------------------------------------------
# Return export data. The default export is just a sequence of index numbers
# (the 'n' attribute of Game class). If the 'full' argument is true, then
# result of Game's 'export' method is returned instead of each index. This
# is used when creating the master game list for other parts of the export
# data to references.
#-----------------------------------------------------------------------------

sub export_games
{
  my ($self, $full) = @_;
  my $c = $self->count_games();
  my @d;

  for(my $i = 0; $i < $c; $i++) {
    $d[$i] = $full ? $self->games()->[$i]->export() : $self->games->[$i]->n();
  }

  return \@d;
}


#-----------------------------------------------------------------------------
# Output the game list as xlogfile rows (through a call-back).
#-----------------------------------------------------------------------------

sub export_xlogfile
{
  my ($self, $cb) = @_;
  my $cfg = TNNT::Config->instance()->config();

  #--- sanity checks, we are doing them here so that the Game/export_xlogfile
  #--- doesn't have to do them for every line

  return undef if !ref($cb);

  if(
    !exists $cfg->{'fields'}
    || !ref $cfg->{'fields'}
    || !@{$cfg->{'fields'}}
  ) {
    die "Tried to --coalesce xlogfile, but fields not configured\n";
  }

  #--- invoke export_xlogfile() on each game and return the result

  $self->iter_games(sub {
    $cb->($_->export_xlogfile());
  });
}



#=============================================================================

1;
