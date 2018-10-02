#!/usr/bin/env perl

#=============================================================================
# Template processing
#=============================================================================

package TNNT::Template;

use Carp;
use FindBin qw($Bin);
use Moo;
use TNNT::Config;
use Template;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has data => (
  is => 'ro',
  required => 1,
);

has config => (
  is => 'ro',
  builder => 1,
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Builder for 'config' attribute
#-----------------------------------------------------------------------------

sub _build_config
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  if(!exists $cfg->{'templates'}) {
    die 'No templates defined in configuration file';
  }

  return $cfg->{'templates'};
}


#-----------------------------------------------------------------------------
# Template processing, lifted right right from Devnull Tribute code.
#-----------------------------------------------------------------------------

sub process
{
  my ($self, $dir, $iter_var, $iter_vals) = @_;

  if(!defined $iter_vals) { $iter_vals = [ undef ]; };

  my $src_path = join('/', grep { $_ } ($self->config()->{'path'}, $dir));
  my $dst_path = join('/', grep { $_ } ($self->config()->{'html'}, $dir));
  my $inc_path = $self->config()->{'include'};

  if($src_path !~ /^\//) {
    $src_path = "$Bin/$src_path";
  }

  if($dst_path !~ /^\//) {
    $dst_path = "$Bin/$dst_path";
  }

  if($inc_path !~ /^\//) {
    $inc_path = "$Bin/$inc_path";
  }

  #--- initialize Template Toolkit

  my $tt = Template->new(
    'OUTPUT_PATH' => $dst_path,
    'INCLUDE_PATH' => [
      $src_path,
      $inc_path,
    ],
    'RELATIVE' => 1,
  );

  if(!ref($tt)) { die 'Failed to initialize Template Toolkit'; }

  #--- find the templates

  my @templates;

  if(! -d $src_path) { croak 'Non-existent template path'; }

  opendir(my $dh, $src_path)
    or die "Could not open template directory '$src_path'";
  @templates = grep {
    /^.*\.tt$/
    && -f "$src_path/$_"
  } readdir($dh);
  closedir($dh);

  return if !@templates;

  #--- iterate over template files

  foreach my $template (@templates) {

  #--- iterate over supplied iteration values

    foreach my $val (@$iter_vals) {

  #--- body of the iteration

      my $dest_file = $template;
      $dest_file =~ s/\.tt$//;

      # if the iteration values are defined, ie. not from the dummy list
      # then temporarily insert them into the user data

      if(defined $iter_var && defined $val) {
        $self->data()->{$iter_var} = $val;
      }

      # if the iteration variable and template filename (without suffix)
      # match, then make the output filename be the iteration variable _value_,
      # For example if the template file is 'player.tt' and the iteration
      # variable is player = [ 'adeon', 'stth', 'raisse' ... ] then the
      # generated pages will be adeon.html, stth.html, raisse.html ...

      if(defined $iter_var && $dest_file eq $iter_var) {
        $dest_file = $val;
      }

      # otherwise, the output file will be named "value-template.html"

      elsif(defined $val) {
        $dest_file = "$val-$dest_file";
      }

      # now perform the template processing

      if(!$tt->process($template, $self->data(), $dest_file . '.html')) {
        die $tt->error();
      }

      # remove temporary data

      if(defined $iter_var && defined $val) {
        delete $self->data()->{$iter_var};
      }
    }
  }
}


#=============================================================================

1;
