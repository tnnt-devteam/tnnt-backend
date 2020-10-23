#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Conduct;

use Carp;
use Moo;
use TNNT::ScoringEntry;
use TNNT::Game;
use Data::Dump qw(dd);


#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'conduct',
);

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

<<<<<<< HEAD
=======
#-----------------------------------------------------------------------------
# Return a ref to player tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
  } elsif($subj_type eq 'clan') {
    return $self->_clan_track();
  }

  croak "Invalid argument to Conduct->_track($subj_type)";
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
    croak 'Invalid argument to GreatFoo->track_data(), must be Player or Clan';
  }
}

>>>>>>> main
sub add_game
{
  my (
    $self,
    $game,
  ) = @_;
  my $cfg = TNNT::Config->instance()->config();
  #--- only ascended games
  if (!$game->is_ascended()) {
    return;
  }

  my @conducts = $game->conducts();
  my $multiplier = 1;
  foreach my $conduct (@conducts) {
    $multiplier *= $cfg->{'trophies'}{"conduct:$conduct"}{'multi'};
  }
  $multiplier--;

  my $se = new TNNT::ScoringEntry(
    trophy => $self->name(),
    when => $game->endtime,
    points => 0,
    data => {
      conducts => [ $game->conducts() ],
      conducts_txt => join(' ', $game->conducts()),
      ncond => scalar($game->conducts()),
      multiplier => $multiplier,
    }
  );
  $game->add_score($se);
  #--- finish

  return $self;
}

sub finish
{
}



#=============================================================================

1;
