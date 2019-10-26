#!/usr/bin/env perl

#=============================================================================
# Loading and access to configuration
#=============================================================================

package TNNT::Config;

use Moo;
with 'MooX::Singleton';

use JSON;
use Scalar::Util qw(blessed);
use Carp;



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
  no warnings 'portable';

  my ($self) = @_;
  my $achievements = $self->config()->{'achievements'};

  return [ sort {
    my ($ach_a, $ach_b) = ($a, $b);
    my ($field_a) = grep {
      exists $achievements->{$ach_a}{$_}
    } (qw(achieve tnntachieve0 tnntachieve1 tnntachieve2 tnntachieve3));
    my ($field_b) = grep {
      exists $achievements->{$ach_b}{$_}
    } (qw(achieve tnntachieve0 tnntachieve1 tnntachieve2 tnntachieve3));

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
    || exists $achievements->{$_}{'tnntachieve3'}
  } keys %$achievements ];
}


#-----------------------------------------------------------------------------
# Sources iterator. The callback gets a hash of arguments take from the config
# file plus 'name' that contains the shortname. These can be fed directly to
# TNNT::Sources constructor.
#-----------------------------------------------------------------------------

sub iter_sources
{
  my ($self, $cb) = @_;
  my $sources = $self->config()->{'sources'};

  for my $src (keys %$sources) {
    $cb->(
      name => $src,
      %{$self->config()->{'sources'}{$src}},
    );
  }
}


#-----------------------------------------------------------------------------
# For given point of time returns -1 = before/0 = during/1 = after depending
# on tournament time limits configuration. The argument can have three forms:
#
# - Game instance ref, then starttime/endtime attributes are used
# - scalar, then it is taken as a single time point
# - undefined, the above option is taken with current time
#-----------------------------------------------------------------------------

sub time_phase
{
  my ($self, $t) = @_;
  my ($tcfg, $cfg_starttime, $cfg_endtime);

  #--- if the entire time section in config is missing, be always in 'during'
  #--- phase

  return 0 if !exists $self->config()->{'time'};
  $tcfg = $self->config()->{'time'};

  #--- if the argument is undefined, use current time

  if(!defined $t) {
    $t = time();
  }

  #--- load the limits

  if(exists $tcfg->{'starttime'}) { $cfg_starttime = $tcfg->{'starttime'} };
  if(exists $tcfg->{'endtime'})   { $cfg_endtime   = $tcfg->{'endtime'}   };

  #--- if the argument is a Game reference, check whether the game is in-range

  if(blessed $t && $t->isa('TNNT::Game')) {
    if(defined $cfg_starttime && $t->starttime() < $cfg_starttime) {
      return -1;
    }
    if(defined $cfg_endtime && $t->endtime() >= $cfg_endtime) {
      return 1;
    }
    return 0
  }

  #--- if the argument is a reference, it's invalid

  elsif(ref $t) {
    croak 'TNNT::Config/time_phase: Argument is an invalid reference';
  }

  #--- the argument is scalar non-reference, we will consider it a single time
  #--- point

  else {
    if(defined $cfg_starttime && $t < $cfg_starttime) { return -1; }
    if(defined $cfg_endtime && $t >= $cfg_endtime) { return 1; }
    return 0;
  }
}



#=============================================================================

1;
