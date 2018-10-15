#!/usr/bin/env perl

#=============================================================================
# Processing of the command-line options.
#=============================================================================

package TNNT::Cmdline;

use Moo;
with 'MooX::Singleton';

use Getopt::Long;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# --debug
# currently this does nothing

has debug => (
  is => 'rwp',
);

# --json
# this makes the scoreboard dump the internal data as JSON text to standard
# output or a user-specified file; disabled by default

has json => (
  is => 'rwp',
);

# --html
# this makes the scoreboard use the internal data to compile target HTML
# files with configured templates; enabled by default, so to actually make
# this do anything, use the inverted form: --nohtml

has html => (
  is => 'rwp',
  default => 1,
);



#=============================================================================
# Initialize the object according to the command-line options given
#=============================================================================

sub BUILD {
  my ($self, $args) = @_;

  if(!GetOptions(
    'debug'   => sub { $self->_set_debug(1); },
    'json:s'  => sub { $self->_set_json($_[1]); },
    'html!'   => sub { $self->_set_html($_[1]); },
    'help'    => sub { $self->help(); },
  )) {
    die 'Invalid command-line argument';
  }
};


#-----------------------------------------------------------------------------
# Display summary of options, then exit
#-----------------------------------------------------------------------------

sub help
{
  print <<EOHD;

THE NOVEMBER NETHACK TOURNAMENT scoreboard
""""""""""""""""""""""""""""""""""""""""""
Command line options:

  --debug        turn on debug mode
  --nohtml       do not compile templates to HTML
  --json[=FILE]  dump JSON data to STDOUT or user-specified file
  --help         display this help

EOHD

  exit(0);
}



#=============================================================================

1;
