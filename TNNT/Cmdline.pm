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
# this inhibits compiling templates into HTML files and instead outputs JSON
# data into standard output

has json_only => (
  is => 'rwp',
);



#=============================================================================
# Initialize the object according to the command-line options given
#=============================================================================

sub BUILD {
  my ($self, $args) = @_;

  if(!GetOptions(
    'debug'   => sub { $self->_set_debug(1); },
    'json:s'  => sub { $self->_set_json_only($_[1]); },
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
  --json[=FILE]  output JSON data to STDOUT or user-specified file instead of
                 compiling templates into HTML files
  --help         display this help

EOHD

  exit(0);
}



#=============================================================================

1;
