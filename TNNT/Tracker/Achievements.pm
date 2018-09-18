#!/usr/bin/env perl

#=============================================================================
# Tracker for player/clan achievements.
#=============================================================================

package TNNT::Tracker::Achievements;

use Moo;
use TNNT::ScoringEntry;
use TNNT::ClanList;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'achievements',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Process a single game
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player);

  for my $ach (@{$game->achievements()}) {

  #--- individual players

    if(!grep { $_ eq $ach } @{$player->achievements()}) {
      push(@{$player->achievements()}, $ach);

      $player->add_score(TNNT::ScoringEntry->new(
        trophy => 'ach:' . $ach,
        when => $game->endtime(),
        game => [ $game ],
      ));

    }

  #--- clans

    if($clan && !grep { $_ eq $ach } @{$clan->achievements()}) {
      push(@{$clan->achievements()}, $ach);

      $clan->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-ach:' . $ach,
        when => $game->endtime(),
        game => [ $game ],
      ));
    }

  }
}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
  my ($self) = @_;

  return $self;
}



#=============================================================================

1;
