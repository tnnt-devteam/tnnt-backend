#!/usr/bin/env perl

#=============================================================================
# Handling of xlogfile sources. Pass xlogfile name to the constructor, then
# (repeatedly) use 'read' method to read the contents.
#=============================================================================



package TNNT::Source;

use Try::Tiny;
use Carp;
use Moo;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

#--- source xlogfile

has logfile => (
  is => 'ro',
  required => 1,
  isa => sub {
    die "File '$_[0]' does not exist or not readable"
    unless -r $_[0];
  },
);

#--- current file position

has fpos => (
  is => 'rwp',
);

#--- curent number of lines parsed

has lines => (
  is => 'rwp',
);



#=============================================================================
#=== PRIVATE METHODS =========================================================
#=============================================================================

#=============================================================================
# Parse single row of xlogfile and return the result as hashref
#=============================================================================

sub _parse_xlogfile_row
{
  my (
    $self,
    $line,
  ) = @_;

  my %result;

  my @row = split(/\t/, $line);

  foreach my $key_value_pair (@row) {
    $key_value_pair =~ /^(.+?)=(.+)$/;
    $result{$1} = $2 unless exists $result{$1};
  }

  return \%result;
}


#=============================================================================
#=== PUBLIC METHODS ==========================================================
#=============================================================================

#=============================================================================
# Read xlogfile and pass parsed lines to a callback.
#=============================================================================

sub read
{
  #--- arguments

  my (
    $self,
    $cb,        # 1. callback that gets a parsed line (hashref)
  ) = @_;

  #--- other variables

  my $file = $self->logfile();
  my $fpos = $self->fpos();
  my $lines = $self->lines();
  my ($fh, $re_open, $re_seek);

  try { #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  #--- open the xlogfile

    $re_open = open($fh, '<', $file);
    die "Cannot open file '$file'" if !$re_open;

  #--- if the file was read before, seek into the new part of the file

    if($fpos) {
      $re_seek = seek($fh, $fpos, 0);
      die "Cannot seek into file '$file'" if !$re_seek;
    }

  #--- read the file

    while(my $l = <$fh>) {
      chomp($l);
      my $row = $self->_parse_xlogfile_row($l);
      $cb->($row);
      $lines++;
    }

  } #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  catch {
    close($fh) if $re_open;
    croak $_;
  };

  #--- finish

  $self->_set_lines($lines);
  $self->_set_fpos(tell($fh));
  close($fh);
}


1;
