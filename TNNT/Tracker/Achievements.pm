#!/usr/bin/env perl

#=============================================================================
# Tracker for player/clan achievements.
#=============================================================================

package TNNT::Tracker::Achievements;

use Moo;
use TNNT::ScoringEntry;
use TNNT::Config;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'achievements',
);

has players_track => (
  is => 'ro',
  default => sub { [] },
);

has clans_track => (
  is => 'ro',
  default => sub { [] },
);

has total_ach_number => (
  is => 'ro',
  builder => 1,
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Builder for total_ach_number attribute.
#-----------------------------------------------------------------------------

sub _build_total_ach_number
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  return scalar(keys %{$cfg->{'achievements'}});
}


#-----------------------------------------------------------------------------
# Process a single game
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clan = $player->clan();

  for my $ach (@{$game->achievements()}) {

  #--- individual players

    if(!grep { $_ eq $ach } @{$player->achievements()}) {
      push(@{$player->achievements()}, $ach);

      $player->add_score(TNNT::ScoringEntry->new(
        trophy => 'ach:' . $ach,
        when => $game->endtime(),
        game => [ $game ],
      ));

      # check if all achievements were attained and create a scoring entry
      # and mark the player

      if(@{$player->achievements()} == $self->total_ach_number()) {
        $player->add_score(TNNT::ScoringEntry->new(
          trophy => 'allachieve',
          when => $game->endtime(),
          game => [ $game ],
          points => $self->total_ach_number(),
        ));
        push(@{$self->players_track()}, $player->name());
      }
    }

  #--- clans

    if($clan && !grep { $_ eq $ach } @{$clan->achievements()}) {
      push(@{$clan->achievements()}, $ach);

      $clan->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-ach:' . $ach,
        when => $game->endtime(),
        game => [ $game ],
      ));

      # check if all achievements were attained and create a scoring entry
      # and mark the clan

      if(@{$clan->achievements()} == $self->total_ach_number()) {
        $clan->add_score(TNNT::ScoringEntry->new(
          trophy => 'clan-allachieve',
          when => $game->endtime(),
          game => [ $game ],
          points => $self->total_ach_number(),
        ));
        push(@{$self->clans_track()}, $clan->n());
      }
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
