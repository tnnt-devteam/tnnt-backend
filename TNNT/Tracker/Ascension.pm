#!/usr/bin/env perl

#=============================================================================
# Tracker for single ascensions for both players and clans. Ascension score
# is summed from the following components:
#
# 1) Ascension value scaled down with z-score based on role-race combination
# 2) Conducts bonus
# 3) Speedrunning bonus
# 4) Streak bonus
#
# The 'data' attribute contains 'breakdown' key that contains breakdown of the
# ascension score. Following hash keys are present
#
# - bpoints   ... base point value of the ascension
# - zpoints   ... z-scaled value of the ascension
# - repeat    ... how many times this character combo was won
#=============================================================================

package TNNT::Tracker::Ascension;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'ascension',
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

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  #--- variables

  my $ptrk = $self->_player_track;   # player track shortcut
  my %breakdown;                     # scoring breakdown

  #--- only ascended games

  return if !$game->is_ascended();

  #--- track player ascensions and get z-score divisor

  my $pzdivisor = ++$ptrk->{$game->name}{$game->role}{$game->race};

  #--- create scoring entry

  my $se = new TNNT::ScoringEntry(
    trophy => $self->name(),
    games => [ $game ],
    when => $game->endtime(),
    data => { 'breakdown' => \%breakdown },
  );

  $breakdown{'bpoints'} = $se->points;

  $game->player()->add_score($se);
  $game->add_score($se);

  #--- apply z-score scale-down to the point value

  $se->points(int($se->points / $pzdivisor));
  $breakdown{'zpoints'} = $se->points;
  $breakdown{'repeat'} = $pzdivisor;

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
