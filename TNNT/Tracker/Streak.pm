#!/usr/bin/env perl

#=============================================================================
# Streak tracker. This class maintains list of potential and actual streaks
# per player, awards points for streak according to the rules and also tracks
# the longest streak.
#
# The actual streak logic is implemented in TNNT::StreakList.
#=============================================================================

package TNNT::Tracker::Streak;

use Moo;
use TNNT::ScoringEntry;
use TNNT::StreakList;
use TNNT::Streak;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'streak',
);

# hash of players pointing to TNNT::StreakList objects

has players => (
  is => 'rw',
  default => sub { {}; },
);

# longest streak

has maxstreak => (
  is => 'rwp',
  default => sub { new TNNT::Streak; },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return player object for current maxstreak. If the maxstreak is an empty
# list, return undef.
#-----------------------------------------------------------------------------

sub player
{
  my ($self) = @_;

  return (
    $self->maxstreak()->count_games()
    ?
    $self->maxstreak()->last_game()->player()
    :
    undef
  );
}


#-----------------------------------------------------------------------------
# Return clan object for current maxstreak. If the maxstreak is an empty list
# or the player is not in a clan, return undef.
#-----------------------------------------------------------------------------

sub clan
{
  my ($self) = @_;
  my $player = $self->player();

  return if !$player;

  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player);

  return $clan;
}



#=============================================================================
# Process one game.
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player_name = $game->player()->name();

  #--- if the player is already tracked, just invoke 'add_game' on his
  #--- StreakList instance

  if($self->player_streak($player_name)) {
    $self->player_streak($player_name)->add_game($game, sub {
      $game->player()->add_score($self->score($_[0]));
    });
  }

  #--- if the player IS NOT yet tracked, create new StreakList instance for
  #--- them and add the first game

  else {
    $self->players()->{$player_name} = new TNNT::StreakList();
    $self->player_streak($player_name)->add_game($game);
  }

  # check current player if they still have streak and if not, remove the
  # player entry entirely

  $self->untrack_if_empty($player_name);
}



#=============================================================================
# Create player scoring entry for a streak and as a side-effect also track
# the longest streak trophy (FIXME: This is not very elegant)
#=============================================================================

sub score
{
  my ($self, $streak) = @_;

  #--- compute score for the streak

  my $bonus = 0;
  my $factor = 0;

  $streak->iter_games(sub{
    $bonus += int(
      $_[0]->sum_score('ascension', 'conduct', 'speedrun') * $factor
    );
    $factor += 0.1;
  });

  #--- handle longest streak tracking

  if(
    $streak->count_games() > $self->maxstreak()->count_games()
  ) {

  # remove scoring entry from previous holder

    if($self->player()) {
      $self->player()->remove_score('maxstreak');
    }
    if($self->clan()) {
      $self->clan()->remove_score('clan-maxstreak');
    }

  # set the tracking attributes

    $self->_set_maxstreak($streak);

  # add scoring entry to new holder

    $self->player()->add_score(new TNNT::ScoringEntry(
      trophy => 'maxstreak',
      games => $streak,
      data  => { len => $streak-> count_games() },
      when => $streak->last_game()->endtime(),
    ));

    if($self->clan()) {
      $self->clan()->add_score(new TNNT::ScoringEntry(
        trophy => 'clan-maxstreak',
        games => $streak,
        data  => { len => $streak-> count_games() },
        when => $streak->last_game()->endtime(),
      ));
    }

  }

  #--- create the scoring entry

  return new TNNT::ScoringEntry(
    trophy => $self->name(),
    games => $streak->games(),
    data => { len => $streak->count_games() },
    when => $streak->last_game()->endtime(),
    points => $bonus,
  );

}



#=============================================================================
# Simple getter to get a player's StreakList by name. Returns undef if player
# is not tracked.
#=============================================================================

sub player_streak
{
  my ($self, $player_name) = @_;

  return $self->players()->{$player_name} // undef;
}



#=============================================================================
# Return list of players we are currently tracking.
#=============================================================================

sub player_names
{
  my ($self) = @_;

  return keys %{$self->players()};
}


#=============================================================================
# This removes a player from tracking if they do not have any streaks going.
#=============================================================================

sub untrack_if_empty
{
  my ($self, $player_name) = @_;

  if(!$self->player_streak($player_name)->count_streaks()) {
    delete $self->players()->{$player_name};
  }

  return $self;
}



#=============================================================================
# Close all open streak in order to generate scoring entries, because streak
# tracker will only generate them on closing. If this wouldn't be done, open
# streaks wouldn't generate their scoring entries.
#=============================================================================

sub finish
{
  my ($self) = @_;

  foreach my $player_name ($self->player_names()) {
    $self->player_streak($player_name)->close(sub {
      $_[0]->last_game()->player()->add_score($self->score($_[0]));
    });
    $self->untrack_if_empty($player_name);
  }

  return $self;
}



#=============================================================================

1;
