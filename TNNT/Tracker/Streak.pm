#!/usr/bin/env perl

#=============================================================================
# Streak tracker. This class maintains list of potential and actual streaks
# per player, awards points for streak according to the rules and also tracks
# the longest streak.
#
# The actual streak logic is implemented in TNNT::StreakList.
#=============================================================================

package TNNT::Tracker::Streak;

use Carp;
use Moo;
use TNNT::Game;
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
);

has _player_track => (
  is => 'ro',
  default => sub { {} },
);

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return a ref to player tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
  }# elsif($subj_type eq 'clan') {
  #  return $self->_clan_track();
  #}

  croak "Invalid argument to Streak->_track($subj_type)";
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
  }# elsif($subj->isa('TNNT::Clan')) {
  #  if(!exists $self->_clan_track()->{$subj->n()}) {
  #    return $self->_clan_track()->{$subj->n()} = {};
  #  } else {
  #    return $self->_clan_track()->{$subj->n()};
  #  }
  #} else {
  #  croak 'Invalid argument to GreatFoo->track_data(), must be Player or Clan';
  #}
}
#-----------------------------------------------------------------------------
# Return player object for current maxstreak. If the maxstreak is an empty
# list, return undef.
#-----------------------------------------------------------------------------

sub player
{
  my ($self) = @_;

  return (
    defined $self->maxstreak() && $self->maxstreak()->count_games()
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

  return $player->clan();
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

  # get/set saved semi-persistant player asc data
  # this code should be refactored as it appears in multiple places but whatever fml
  my $player = $game->player();
  my $tracker = $self->_track_data($player);
  if ($game->is_ascended()) {
    # if we skip all this code for non-ascended games, the streak computer
    # will think every asc is a streak xD
    $tracker->{'asc_count'} = 0 if !defined($tracker->{'asc_count'});
    $tracker->{'asc_count'}++;
    $tracker->{'previous_asc'} = $tracker->{'this_asc'};
    $tracker->{'this_asc'} = $game; # need to update for first game of streak
  }

  if($self->player_streak($player_name)) {
    $self->player_streak($player_name)->add_game($game, $self, $player, $tracker, \&close_streak_cb, \&increment_streak_cb);
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

# game adding callback, gets (self, game, index) as argument
sub increment_streak_cb {
  my ($game,
      $player,
      $tracker,
      $streak_index) = @_;
  die if !$game->isa('TNNT::Game');

  my $multi = 1 + ($streak_index * 0.1);
  $multi = 1.5 if $multi > 1.5; # don't forget the cap
  $game->add_score(TNNT::ScoringEntry->new(
    trophy => 'streak',
    when => $game->endtime,
    points => 0,
    data => {
      streakidx => $streak_index,
      streakmult => $multi,
    },
  ));

  if (!defined $tracker->{'active_streak'}) {
    # means we are dealing with second game of a streak
    push @{$tracker->{'active_streak'}}, {
      game => $tracker->{'previous_asc'},
      index => 0,
      multiplier => 1, #gonna back-update this anyway so
      key => $player->name . "-" . ($tracker->{'asc_count'} - 1)
    };
    $tracker->{'previous_asc'}->add_score(TNNT::ScoringEntry->new(
      trophy => 'streak',
      when => $game->endtime,
      points => 0,
      data => {
        streakidx => 0,
        streakmult => 1,
      },
    ));
  }
  my $streak_entry = {game => $game,
                      index => $streak_index,
                      multiplier => $multi,
                      key => $player->name . "-" . $tracker->{'asc_count'}};
  push @{$tracker->{'active_streak'}}, $streak_entry;
  
  # loop over previous streak games, starting from n-1 !!
  my @streak_games = @{$tracker->{'active_streak'}};
  for (my $i = $streak_index - 1; $i >= 0; $i--) {
    my $key = $streak_games[$i]->{'key'};
    # ah crap, streak points depend on conduct points and everything else of the score,
    # thus we have to also update that when a conduct score is updated FML
    # in general the code for updating prior games should be refactored somehow because atm
    # the same blocks of boilerplate appear multiple times...
    #print "processing game $i, key = $key, multi = $multi\n";
    my $asc_se = $player->get_score_by_key("asckey", $key);
    next if !$asc_se;
    my $streak = $streak_games[$i]->{'game'}->get_score('streak');
    next if !$streak;
    $streak->{'data'}{'streakmult'} = $multi;
    $streak->{'data'}{'streakidx'} = ($streak_games[$i]->{'index'} + 1);

    # update old game score - streak bonus is meant to be
    # dependent on everything *except* the zpoints
    my $streak_bonus = int(($asc_se->{'data'}{'breakdown'}{'spoints'}
                           + $asc_se->{'data'}{'breakdown'}{'cpoints'} + 50) * ($multi - 1));
    $asc_se->{'data'}{'breakdown'}{'tpoints'} = $streak_bonus;
    #my $foo = $asc_se->points;
    $asc_se->points($asc_se->{'data'}{'breakdown'}{'zpoints'}
                    + $asc_se->{'data'}{'breakdown'}{'spoints'}
                    + $asc_se->{'data'}{'breakdown'}{'cpoints'}
                    + $asc_se->{'data'}{'breakdown'}{'tpoints'});
    #my $bar = $asc_se->points;
    #print "old_score = $foo, new score = $bar\n";
    $asc_se->{'data'}{'breakdown'}{'streak'}{'multiplier'} = $multi;
    $asc_se->{'data'}{'breakdown'}{'streak'}{'index'} = ($streak_games[$i]->{'index'} + 1);

    my $clan = $player->clan;
    next if !$clan;
    my $clan_asc_se = $clan->get_score_by_key("clan_asckey", $key);
    if (!$clan_asc_se)
    {
      warn "lookup on ascension $key failed";
      next;
    }
    # update old game score
    # idk whether calculating this again is really necesssary...
    # rn i just want to fix the scoring :D
    $clan_asc_se->{'data'}{'breakdown'}{'tpoints'} = $streak_bonus;
    $clan_asc_se->points($clan_asc_se->{'data'}{'breakdown'}{'zpoints'}
                    + $clan_asc_se->{'data'}{'breakdown'}{'spoints'}
                    + $clan_asc_se->{'data'}{'breakdown'}{'cpoints'}
                    + $clan_asc_se->{'data'}{'breakdown'}{'tpoints'});
    $clan_asc_se->{'data'}{'breakdown'}{'streak'}{'multiplier'} = $multi;
    $clan_asc_se->{'data'}{'breakdown'}{'streak'}{'index'} = ($streak_games[$i]->{'index'} + 1);
  }
}

# streak closing callback, gets (streak) as argument
sub close_streak_cb {
  my ($self, $tracker, $streak) = @_;

  $tracker->{'active_streak'} = undef;
  # need to check what this does
  $self->score($streak);
}

#=============================================================================
# Create player scoring entry for a streak and as a side-effect also track
# the longest streak trophy (FIXME: This is not very elegant) and add the
# streak to Player instances for easy access.
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
    !defined $self->maxstreak()
    || $streak->count_games() > $self->maxstreak()->count_games()
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
        data  => {
          len => $streak-> count_games(), achiever => $self->player->name
        },
        when => $streak->last_game()->endtime(),
      ));
    }

  }

  #--- add streak to Player instance

  my $player = $streak->last_game()->player();
  push(
    @{$player->streaks()},
    $streak
  );

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
    
    my $player = $self->get_player($player_name);
    my $tracker = $self->_track_data($player);
    $self->player_streak($player_name)->close(sub {
      $_[1]->{'active_streak'} = undef;
      $_[2]->last_game()->player()->add_score($_[0]->score($_[2]));
    }, $self, $tracker, $self->player_streak($player_name));
    $self->untrack_if_empty($player_name);
  }

  return $self;
}

#-----------------------------------------------------------------------------
# Get player by name.
#-----------------------------------------------------------------------------

sub get_player
{
  my ($self, $name) = @_;
  my $pl = $self->players();

  if(exists $pl->{$name}) {
    return $pl->{$name};
  } else {
    return undef;
  }
}

#=============================================================================

1;
