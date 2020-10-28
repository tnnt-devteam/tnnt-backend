#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Mercy;

use Carp;
use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'mercy',
);

has _player_track => (
  is => 'ro',
  default => sub { {} },
);

has _clan_track => (
  is => 'ro',
  default => sub { {} },
);

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return a ref to player or clan tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
  } elsif($subj_type eq 'clan') {
    return $self->_clan_track();
  }

  croak "Invalid argument to Mercy->_track($subj_type)";
}


#-----------------------------------------------------------------------------
# Return player/clan tracking entry. If it doesn't exist yet, new one is
# created and returned. The argument must be an instance of Player or Clan.
#-----------------------------------------------------------------------------

sub _track_data
{
  my ($self, $subj) = @_;

  if($subj->isa('TNNT::Player')) {
    if(!exists $self->_player_track()->{$subj->name()}) {
      return $self->_player_track()->{$subj->name()} = {};
    } else {
      return $self->_player_track()->{$subj->name()};
    }
  } elsif($subj->isa('TNNT::Clan')) {
    if(!exists $self->_clan_track()->{$subj->n()}) {
      return $self->_clan_track()->{$subj->n()} = {};
    } else {
      return $self->_clan_track()->{$subj->n()};
    }
  } else {
    croak 'Invalid argument to Mercy->track_data(), must be Player or Clan';
  }
}

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  #--- only ascended games

  return if !$game->is_ascended();

  my $cfg = TNNT::Config->instance()->config();
  my $player = $game->player;
  my $clan = $player->clan;
  for my $entity ($player, $clan) {
    # get tracking structure for player or clan
    next if !$entity;
    my $trk = $self->_track_data($entity);
    foreach my $mercy ($game->mercies()) {
      #--- check if player already has this trophy, then
      # add scoring entry for that
      if(!$trk || !$trk->{"mercy:$mercy"}) {
        my $se = new TNNT::ScoringEntry(
          trophy => "mercy:$mercy",
          when => $game->endtime(),
          game => [ $game ]
        );
        $trk->{"mercy:$mercy"} = 1;
        $entity->add_score($se);
      }
    }
  }

  #--- finish

  return $self;
}

sub export
{
  my ($self) = @_;
  # mercies subfield is found under conducts because they're defined within the conduct bitfields
  my $cfg = TNNT::Config->instance()->config()->{'conducts'};
  my @mercies = @{$cfg->{'mercies'}};
  my %trophy_holders;

  foreach my $entity_type ('player', 'clan') {
    my $entity_list = $self->_track($entity_type);
    foreach my $entity_name (keys %$entity_list) {
      my $entity_trk = $entity_list->{$entity_name};
      for my $mercy (@mercies) {
        if ($entity_trk && $entity_trk->{"mercy:$mercy"}) {
          # add entity's name to the list of those holding the given mercy trophy
          # entity type is singular but the hash %trophy_holders is with plural keys
          push @{$trophy_holders{"${entity_type}s"}{$mercy}}, $entity_name;
        }
      }
    }
  }

  return ($trophy_holders{'players'}, $trophy_holders{'clans'});
}

sub finish
{
}



#=============================================================================

1;
