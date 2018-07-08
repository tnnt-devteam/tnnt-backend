#!/usr/bin/env perl

#=============================================================================
# Utility to randomize chronological order of a xlogfile. This is used to test
# out-of-order processing.
#=============================================================================

use List::Util 'shuffle';

my @xlogfile;

while(my $l = <>) {
  push(@xlogfile, $l);
}

foreach (shuffle @xlogfile) {
  print $_;
}
