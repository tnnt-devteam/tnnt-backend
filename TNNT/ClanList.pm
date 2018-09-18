#!/usr/bin/env perl

#=============================================================================
# Loading and access to clan database. This is basically an external
# configuration, so we handle this in as a singleton object.
#=============================================================================

package TNNT::ClanList;

use Moo;
use DBI;
use TNNT::Config;
use TNNT::Clan;
with 'MooX::Singleton';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has clans => (
  is => 'rw',
  builder => '_load_clans',
);



#=============================================================================
# Config loading
#=============================================================================

sub _load_clans
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  #--- ensure the database file even exists

  if(!-r $cfg->{'clandb'}) {
    die 'Cannot read clan database file ' . $self->config_file();
  }

  #--- open the database file

  my $dbh = DBI->connect(
    'dbi:SQLite:dbname=' . $cfg->{'clandb'},
    undef, undef
  );

  if(!ref($dbh)) {
    die "Failed to open clan database at " . $cfg->{'clandb'};
  }

  #--- prepare and execute the query

  my $sth = $dbh->prepare(
    'SELECT players.name AS name, clans.name AS clan, clan_admin ' .
    'FROM players JOIN clans USING (clans_i)'
  );

  my $r = $sth->execute();
  if(!$r) {
    die sprintf('Failed to query clan database (%s)', $sth->errstr());
  }

  #--- read the clan info from the database

  my %clans;

  while(my $h = $sth->fetchrow_hashref()) {
    my $clan = $h->{'clan'};
    if(!exists $clans{$clan}) {
      $clans{$clan} = new TNNT::Clan(name => $clan);
    }
    $clans{$clan}->add_player(
      $h->{'name'},
      $h->{'clan_admin'}
    );
  }

  #--- finish

  return \%clans;
}


#=============================================================================
# Clans iterator function.
#=============================================================================

sub iter_clans
{
  my ($self, $cb) = @_;

  for my $clan (sort keys %{$self->clans()}) {
    $cb->($self->clans()->{$clan});
  }

  return $self;
}



#=============================================================================
# Find clan by playername or player object ref.
#=============================================================================

sub find_clan
{
  my ($self, $player) = @_;

  if(ref($player)) {
    $player = $player->name();
  }

  my ($clan_name) = grep {
    $self->clans()->{$_}->is_member($player)
  } keys %{$self->clans()};

  if($clan_name) {
    return $self->clans()->{$clan_name};
  } else {
    return undef;
  }
}


#-----------------------------------------------------------------------------
# Add games to clans
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;

  my $clan = $self->find_clan($game->player());
  return if !$clan;

  $clan->add_game($game);

  return ($self, $game);
}



#=============================================================================

1;
