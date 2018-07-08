#!/usr/bin/env perl

#=============================================================================
# Loading and access to configuration
#=============================================================================

package TNNT::Config;

use Moo;
with 'MooX::Singleton';

use JSON;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has config_file => (
  is => 'ro',
  required => 1,
);

has config => (
  is => 'lazy',
  builder => '_load_config',
);


#=============================================================================
# Config loading
#=============================================================================

sub _load_config
{
  my ($self) = @_;

 if(-r $self->config_file()) {
   local $/;
   my $js = new JSON->relaxed(1);
   open(my $fh, '<', $self->config_file());
   my $def_json = <$fh>;
   my $cfg = $js->decode($def_json) or die 'Cannot parse the configuration';
   return $cfg;
 } else {
   die 'Cannot read config file ' . $self->config_file();
 }
}



#=============================================================================

1;
