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

has topclan => (
  is => 'rwp',
);

has _clan_track => (
  is => 'ro',
  default => sub { {} },
);

has _config => (
  is => 'ro',
  builder => '_build_config',
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
  my $clan = $clans->find_clan($player->name());

  #--- only clan non-rejected games

  return if !$clan || $self->_is_rejected($game);

  #--- init clan tracking

  if(!exists $self->_clan_track()->{$clan->name()}) {
    $self->_clan_track()->{$clan->name()} = {};
  }

  my $ctrk = $self->_clan_track()->{$clan->name()};
  my $death = $self->_normalize_death($game);

  #--- new unique death

  if(!exists $ctrk->{$death}) {
    $ctrk->{$death} = $game;

    # the first clan game
    if(!$self->topclan()) {
      $clan->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-' . $self->name(),
        game => [ $game ],
        when => $game->endtime(),
        data => { count => scalar(keys %$ctrk) },
      ));
      $self->_set_topclan($clan);
    }

    # change in the lead
    elsif(
      scalar(keys %{$ctrk})
      >
      scalar(keys %{$self->_clan_track()->{$self->topclan()->name()}})
    ) {
      $self->topclan()->remove_score('clan-' . $self->name());
      $clan->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-' . $self->name(),
        game => [ $game ],
        when => $game->endtime(),
        data => { count => scalar(keys %$ctrk) },
      ));
      $self->_set_topclan($clan);
    }
  }
}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
}



#=============================================================================

1;
