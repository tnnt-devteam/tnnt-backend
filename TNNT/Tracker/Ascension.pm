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
# - cpoints   ... bonus for conducts
# - spoints   ... speedrunning bonus
# - tpoints   ... streak bonus
# - repeat    ... how many times this character combo was won
# - conducts  ... info about conducts, not present if all broken
# - streak    ... info about streak the game is part of
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

  #--- only ascended games

  return if !$game->is_ascended();

  #--- will be easier to use the same key to lookup games in both the
  #--- payer scores/games list and the clan one, for streak retro updates
  #--- also need to move the initialisation for asc_count = 0 to up here
  #--- and the increment, since all this is per-player now not any entity
  my $trk = $self->_player_track;
  my $player_name = $game->player->name;
  $trk->{'asc_count'}{$player_name} = 0 if !defined($trk->{'asc_count'});
  $trk->{'asc_count'}{$player_name}++;
  my $asc_key = $player_name . "-" . $trk->{'asc_count'}{$player_name};

  #--- list of entities (players, clans) we'll be processing

  my @entities = ($game->player);
  push(@entities, $game->player->clan) if $game->player->clan;

  #--- iterate over entities

  foreach my $entity (@entities) {
    my $is_clan = $entity->isa('TNNT::Clan');
    my %breakdown;
  #--- track ascensions and get number of repeated wins for current game's
  #--- role-race combination

    my $zdivisor = ++$trk->{$entity->name}{$game->role};

  #--- create scoring entry
    my $se = new TNNT::ScoringEntry(
      trophy => ($is_clan ? 'clan-':'') . $self->name(),
      games => [ $game ],
      when => $game->endtime(),
      data => { 'breakdown' => \%breakdown, achiever => $game->name,
                ($is_clan ? 'clan_':'') . 'asckey' => $asc_key },
    );

  #--- get base value for ascension

    my $base = $breakdown{'bpoints'} = $se->points;

  #--- attach the scoring entries to player/clan

    $entity->add_score($se);

  #--- apply z-score scale-down to the point value

    $breakdown{'zpoints'} = int($base / $zdivisor);
    $breakdown{'repeat'} = $zdivisor;
    $breakdown{'combo'} = $game->role;

  #--- add conduct bonus
  # The 'conduct' scoring list is added to ascended games by the 'Conduct'
  # tracker, which must run before this one

    if(my $conduct_se = $game->get_score('conduct')) {
      $breakdown{'conducts'} = $conduct_se->data;
      $breakdown{'cpoints'} = int($base * $breakdown{'conducts'}{'multiplier'});
    } else {
      $breakdown{'cpoints'} = 0;
    }

  #--- add speedrunning bonus
  # The 'speedrun' scoring list is added to ascended games by the 'Conduct'
  # tracker, which must run before this one

    if(my $speedrun_se = $game->get_score('speedrun')) {
      $breakdown{'spoints'} = $speedrun_se->get_data('speedrun');
      $breakdown{'turns'} = $game->turns;
    } else {
      $breakdown{'spoints'} = 0;
    }

  #--- add streaking bonus
  # The 'streak' scoring list is added to ascended games by the 'Streak'
  # tracker, which must run before this one. Bonus for streaking is different
  # from the previous one in that it takes the sum of all the zscore, conduct
  # bonus and speedrun bonus and adds a multiplier, which increases with the
  # number of streaked games

    if(my $streak_se = $game->get_score('streak')) {
      my $streak_multiplier;
      $streak_multiplier = $streak_se->get_data('streakmult');
      $breakdown{'streak'}{'multiplier'} = $streak_multiplier;
      $breakdown{'streak'}{'index'} = ($streak_se->get_data('streakidx') + 1);
      $breakdown{'tpoints'} = int((
        $base
        + $breakdown{'cpoints'}
        + $breakdown{'spoints'}
      ) * ($streak_multiplier - 1));
    } else {
      $breakdown{'tpoints'} = 0;
    }

  #--- save the final calculated score

    $se->points(
      $breakdown{'zpoints'}         # z-score
      + $breakdown{'cpoints'}       # conduct bonus
      + $breakdown{'spoints'}       # speedrun bonus
      + $breakdown{'tpoints'}       # streak bonus
    );

  #--- end of entity iteration

  }

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
