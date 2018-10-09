#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Unique Deaths" clan trophy.
#=============================================================================

package TNNT::Tracker::UniqueDeaths;

use Moo;
use TNNT::ScoringEntry;
use TNNT::Config;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'uniquedeaths',
);

# reference to the top clan Clan instance

has topclan => (
  is => 'rwp',
);

# tracking structure, the clan ids (Clan's 'n' attribute) are the first level
# hash key, the second level hash key is the normalized death message and
# value is Game intance reference

has _clan_track => (
  is => 'ro',
  default => sub { {} },
);

has _config => (
  is => 'ro',
  builder => '_build_config',
);

# order of clans in the Unique Deaths ladder, the array elements are clan
# instance references

has clan_ladder => (
  is => 'rw',
  default => sub { [] },
);


#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Read death message normalization regexes.
#-----------------------------------------------------------------------------

sub _build_config
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  die if !exists $cfg->{'uniquedeaths'};

  return $cfg->{'uniquedeaths'};
}


#-----------------------------------------------------------------------------
# Return true if the death message matches one of the "reject" regexes.
#-----------------------------------------------------------------------------

sub _is_rejected
{
  my ($self, $game) = @_;

  my $death = $game->death();
  my $reject = $self->_config()->{'reject'};

  return scalar(grep { $game->death() =~ /$_/ } @$reject);
}



#-----------------------------------------------------------------------------
# Normalize death message.
#-----------------------------------------------------------------------------

sub _normalize_death
{
  my ($self, $game) = @_;

  my $death = $game->death();
  for my $entry (@{$self->_config()->{'normalize'}}) {
    my ($re, $repl) = @$entry;
    $death =~ s/$re/$repl/;
  }

  return $death;
}



#-----------------------------------------------------------------------------
# Process one game.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $player->clan();

  #--- only clan non-rejected games

  return if !$clan || $self->_is_rejected($game);

  #--- init clan tracking

  if(!exists $self->_clan_track()->{$clan->n()}) {
    $self->_clan_track()->{$clan->n()} = {};
  }

  my $ctrk = $self->_clan_track()->{$clan->n()};
  my $death = $self->_normalize_death($game);

  #--- if new unique death, add it to the tracking hash, add it to clan's
  #--- unique deaths list, re-sort the clan ladder and see if the unique
  #--- deaths leading clan has changed

  if(!exists $ctrk->{$death}) {

    # track the new unique death
    $ctrk->{$death} = $game;
    push(
      @{$clan->unique_deaths()},
      [ $death, $game ]
    );

    # resort the unique deaths clan ladder
    $self->clan_ladder([
      map {
        $clans->get_by_id($_);
      }
      sort {
        scalar keys %{$self->_clan_track()->{$b}}
        <=>
        scalar keys %{$self->_clan_track()->{$a}}
      } keys %{$self->_clan_track()}
    ]);

    # update clan ranks
    for(my $i = 0; $i < @{$self->clan_ladder()}; $i++) {
      $self->clan_ladder()->[$i]->udeaths_rank($i + 1);
    }

    if(
      # there's no top clan yet
      !$self->topclan()
      # OR there is a new top clan
      || $self->topclan() != $self->clan_ladder()->[0]
    ) {
      # remove old scoring entry
      if($self->topclan()) {
        $self->topclan()->remove_score('clan-' . $self->name());
      }
      # set the new top clan attribute
      $self->_set_topclan($self->clan_ladder()->[0]);
      # create new scoring entry
      $self->topclan()->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-' . $self->name(),
        when => $game->endtime(),
        games => [ $game ],
        data => { uniqdeaths => scalar(keys %$ctrk) },
      ));
    }
  }

  #--- finish

  return $self;
}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
}



#=============================================================================

1;
