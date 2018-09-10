#!/usr/bin/env perl

#=============================================================================
# Tracker for clan ascensions. It uses data from player-scoring trackers,
# so this should be run after these.
#
# The clan ascension scoring uses the values from player ascension scoring,
# but limits it only to the best ascension per combo.
#=============================================================================

package TNNT::Tracker::ClanAscension;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-ascension',
);

# clan tracking information

has clantrk => (
  is => 'rwp',
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

  #--- initialize

  my $clans = TNNT::ClanList->instance();
  my $player_name = $game->player()->name();

  my $clan = $clans->find_clan($player_name);

  #--- following section only run when the player is a clan member

  if($clan) {
    my $clan_name = $clan->name();
    if(!exists $self->clantrk()->{$clan_name}) {
      $self->clantrk()->{$clan_name} = {};
    }
    my $clan_trk = $self->clantrk()->{$clan_name};
    my $combo = join('-',
      $game->role(),
      $game->race(),
      $game->gender(),
      $game->align()
    );

  #--- create new scoring entry

    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games => [ $game ],
      when => $game->endtime,
      points => $game->sum_score(),
      data => { combo => $combo },
    );

    #--- the clan already has the game of the same character combo

    if(
      exists $clan_trk->{$combo}
      && $clan_trk->{$combo} < $game->sum_score()
    ) {
      $clan->remove_and_add('combo', $combo, $se);
      $clan_trk->{$combo} = $game->sum_score();
    }

  #--- new unique combo game for the clan

    elsif(!exists $clan_trk->{$combo}) {
      $clan->add_score($se);
      $clan_trk->{$combo} = $game->sum_score();
    }
  }

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
