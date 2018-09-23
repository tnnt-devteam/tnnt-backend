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


#-----------------------------------------------------------------------------
# Create ordered list of achievements. (Yes, the way I chose to define
# achievements in the config file is stupid, so this simple operation is way
# more complicated than it should be).
#-----------------------------------------------------------------------------

sub order_achievements
{
  my ($self) = @_;
  my $achievements = $self->config()->{'achievements'};

  return [ sort {
    my ($ach_a, $ach_b) = ($a, $b);
    my ($field_a) = grep {
      exists $achievements->{$ach_a}{$_}
    } (qw(achieve tnntachieve0 tnntachieve1 tnntachieve2));
    my ($field_b) = grep {
      exists $achievements->{$ach_b}{$_}
    } (qw(achieve tnntachieve0 tnntachieve1 tnntachieve2));

    # we are here assuming that the order of the field names is actually
    # alphabetically ascending!

    if($field_a ne $field_b) {
      return $field_a cmp $field_b;
    } else {
      return
        hex($achievements->{$ach_a}{$field_a})
        <=>
        hex($achievements->{$ach_b}{$field_b});
    }
  }
  grep {
    exists $achievements->{$_}{'achieve'}
    || exists $achievements->{$_}{'tnntachieve0'}
    || exists $achievements->{$_}{'tnntachieve1'}
    || exists $achievements->{$_}{'tnntachieve2'}
  } keys %$achievements ];
}


#-----------------------------------------------------------------------------
# Sources iterator. The callback gets a hash of arguments containing 'name'
# and 'logfile' keys. These can be fed directly to TNNT::Sources constructor.
#-----------------------------------------------------------------------------

sub iter_sources
{
  my ($self, $cb) = @_;
  my $sources = $self->config()->{'sources'};

  for my $src (keys %$sources) {
    $cb->(
      name => $src,
      logfile => $sources->{$src}{'xlogfile'}
    );
  }
}



#=============================================================================

1;
