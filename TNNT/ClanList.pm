#!/usr/bin/env perl

#=============================================================================
# Loading and access to clan database. This is basically an external
# configuration, so we handle this in as a singleton object.
#=============================================================================

package TNNT::ClanList;

use FindBin qw($Bin);
use Scalar::Util qw(blessed);
use Carp;
use Moo;
use DBI;
use TNNT::Config;
use TNNT::Clan;
with 'MooX::Singleton';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# this is list of Clan instances; the position in this list must be equal to
# the value of Clan's 'n' attribute

has clans => (
  is => 'rw',
  builder => '_load_clans',
);

# this is a playername-to-clan lookup hash, an optimization to speed up
# reading of logfiles

has _players_lookup => (
  is => 'rw',
  default => sub { {} },
);



#-----------------------------------------------------------------------------
# Clan database loading
#-----------------------------------------------------------------------------

sub _load_clans
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  #--- if the configuration entry doesn't exist, just return empty array ref

  if(!exists $cfg->{'clandb'} || !$cfg->{'clandb'}) {
    return [];
  }

  #--- if the clandb specification doesn't specify absolute path, prepend the
  #--- current directory

  my $clandb = $cfg->{'clandb'};
  if($clandb !~ /^\//) {
    $clandb = "$Bin/$clandb";
  }

  #--- ensure the database file exists and is readable

  if(!-r $clandb) {
    die sprintf
      "Clan database file (%s) does not exist or is not readable\n",
      $cfg->{'clandb'};
  }

  #--- open the database file

  my $dbh = DBI->connect(
    'dbi:SQLite:dbname=' . $clandb,
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

  #--- read the clan info from the database into a hash, this hash will then
  #--- be converted into the final array

  my %clans;
  my $i = 0;

  while(my $h = $sth->fetchrow_hashref()) {
    my $clan = $h->{'clan'};
    if(!exists $clans{$clan}) {
      $clans{$clan} = new TNNT::Clan(name => $clan, n => $i++);
    }
    $clans{$clan}->add_player(
      $h->{'name'},
      $h->{'clan_admin'}
    );
  }

  #--- convert hash to array

  my @clans;
  foreach my $clan_name (keys %clans) {
    $clans[ $clans{$clan_name}->n() ] = $clans{$clan_name};
  }

  #--- finish

  return \@clans;
}


#-----------------------------------------------------------------------------
# Clans iterator function.
#-----------------------------------------------------------------------------

sub iter_clans
{
  my ($self, $cb) = @_;

  do { $cb->($_) } for @{$self->clans()};

  return $self;
}



#-----------------------------------------------------------------------------
# Find clan by playername or player object ref.
#-----------------------------------------------------------------------------

sub get_by_player
{
  my ($self, $player) = @_;

  #--- if the player argument is a ref, we take that as a Player class
  #--- instance

  if(blessed $player) {
    croak "Argument 'player' is wrong class" if !$player->isa('TNNT::Player');
    $player = $player->name();
  }

  #--- if the playername already is in the lookup table, return the cached
  #--- value

  if(exists $self->_players_lookup()->{$player}) {
    return $self->_players_lookup()->{$player}
  }

  #--- otherwise we need to perform a search, the result is cached for later
  #--- reuse

  my ($clan) = grep { $_->is_member($player) } @{$self->clans()};
  $self->_players_lookup()->{$player} = $clan;

  #--- finish

  return $clan;
}


#-----------------------------------------------------------------------------
# Return clan by numeric id
#-----------------------------------------------------------------------------

sub get_by_id
{
  my ($self, $id) = @_;

  return $self->clans()->[$id];
}


#-----------------------------------------------------------------------------
# Add games to clans
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;

  my $clan = $self->get_by_player($game->player());
  return if !$clan;

  $clan->add_game($game);

  return ($self, $game);
}


#-----------------------------------------------------------------------------
# Export clan data
#
# NOTE/FIXME: We have decided that the clans will be exposed to the templates
# in a list, not hash. Ie. clan is identified not by its name, but by its
# index in the list. This makes it inconsistent with how players are presented
# and makes it somwhat awkward. The intention was to prevent users putting
# arbitrary strings into URLs.
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;
  my (@clans, @clans_by_score);

  #--- produce list of clans with full information

  $self->iter_clans(sub {
    my ($clan) = @_;
    my $i = $clan->n();

    $clans[$i] = {
      n            => $i,
      name         => $clan->name(),
      players      => $clan->players(),
      admins       => $clan->admins(),
      score        => $clan->sum_score(),
      scores       => $clan->export_scores(),
      games        => $clan->export_games(),
      ascs         => $clan->export_ascensions(),
      achievements => $clan->achievements(),
      udeaths_rank => $clan->udeaths_rank(),
      unique_deaths => [
        map { [ $_->[0], $_->[1]->n() ] } @{$clan->unique_deaths()}
      ],
      unique_ascs  => $clan->export_ascensions(sub {
        $_[0]->clan_unique();
      }),
      games100t    => $clan->games1000t(),
    };

    # ascension ratio

    if($clan->count_ascensions()) {
      $clans[$i]{'ratio'} = sprintf("%3.1f",
        $clan->count_ascensions() / $clan->count_games() * 100
      )
    }

    # trophies (selected trophies for showcasing on the player page)

    my @trophies;
    my $cfg = TNNT::Config->instance()->config();

    my @trophy_names = qw(
      firstasc mostasc mostcond mostach lowscore highscore minturns realtime
      rsimpossible gimpossible maxstreak allroles allraces allaligns allgenders
      allconducts allachieve mostgames uniquedeaths
    );

    for my $race (qw(hum elf dwa gno orc)) {
      push(@trophy_names, "greatrace:$race", "lesserrace:$race");
    }

    for my $role (qw(arc bar cav hea mon pri ran rog val wiz)) {
      push(@trophy_names, "greatrole:$role", "lesserrole:$role");
    }

    for my $trophy (@trophy_names) {
      if(my $s = $clan->get_score("clan-$trophy")) {
        push(@trophies, {
          'trophy' => $trophy,
          'title'  => $cfg->{'trophies'}{"clan-$trophy"}{'title'},
          'when'   => $s->_format_when(),
        });
      }
    }

    $clans[$i]{'trophies'} = \@trophies if @trophies;

  });

  #--- produce list of clan indices ordered by score
  # if score is equal, sorting is by number of ascensions, number of
  # achievements, number of games and clan name, respectively

  @clans_by_score =

  map { $_->{'n'} }
  sort {
    if($b->{'score'} == $a->{'score'}) {
      if(@{$b->{'ascs'}} == @{$a->{'ascs'}}) {
        if(@{$b->{'achievements'}} == @{$a->{'achievements'}}) {
          if(@{$b->{'games'}} == @{$a->{'games'}}) {
            return lc($a->{'name'}) cmp lc($b->{'name'})
          } else {
            return @{$b->{'games'}} <=> @{$a->{'games'}};
          }
        } else {
          return @{$b->{'achievements'}} <=> @{$a->{'achievements'}}
        }
      } else {
        return @{$b->{'ascs'}} <=> @{$a->{'ascs'}}
      }
    } else {
      return $b->{'score'} <=> $a->{'score'}
    }
  } @clans;

  #--- get clans' rank

  for(my $i = 0; $i < @clans_by_score; $i++) {
    if(@{$clans[$clans_by_score[$i]]{'games'}}) {
      $clans[$clans_by_score[$i]]{'rank'} = $i + 1;
    }
  }

  #--- finish

  return {
    all => \@clans,
    ordered => \@clans_by_score,
  };
}



#=============================================================================

1;
