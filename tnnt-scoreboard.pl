#!/usr/bin/env perl

#=============================================================================
# THE NOVEMBER NETHACK TOURNAMENT
# """""""""""""""""""""""""""""""
# Scoreboard generator.
#=============================================================================

use v5.10;

use FindBin qw($Bin);
use lib "$Bin";

use Try::Tiny;
use Moo;
use TNNT::Cmdline;
use TNNT::Config;
use TNNT::Source;
use TNNT::ClanList;
use TNNT::Score;
use TNNT::Template;
use Data::Dumper;

$| = 1;

#--- process command-line arguments

my $cmd;

try {
  $cmd = TNNT::Cmdline->instance();
} catch {
  print STDERR "Invalid command-line arguments\n";
  exit(1);
};

#--- load configuration file

my $cfg = TNNT::Config->instance(config_file => "$Bin/config.json");
$cfg->config();

#--- load clan list

my $clans = TNNT::ClanList->instance();

#--- initialize sources

my @sources;

$cfg->iter_sources(sub {
  push(@sources, TNNT::Source->new(@_));
});

#--- perform reading of the xlogfiles

my $score = TNNT::Score->new();

for my $src (@sources) {
  $src->read(sub { $score->add_game($_[0]) });
}

#--- compile the scoreboard

$score->process();

#--- process the templates

my $data = $score->export();
my $t = TNNT::Template->new(data => $data);
$t->process();
$t->process('players', 'player', $data->{'players'}{'ordered'});
$t->process('clans', 'clan', $data->{'clans'}{'ordered'});
