#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Achievements in one Game" trophy (both individual
# players and clans).
#=============================================================================

package TNNT::Tracker::MostAch;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'mostach',
);

has player => (
  is => 'rwp',
);

has clan => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);

has maxach => (
  is => 'rwp',
  default => sub { 0 },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clan = $player->clan();

  #--- current game has the most conducts so far

  if(@{$game->achievements} > $self->maxach()) {

  #--- remove scoring entry from previous holder (if any)

    if($self->player()) {
      $self->player()->remove_score($self->name());
    }
    if($self->game()) {
      $self->game()->remove_score($self->name());
    }
    if($self->clan()) {
      $self->clan()->remove_score('clan-' . $self->name());
    }

  #--- set player, game and clan

    $self->_set_game($game);
    $self->_set_player($game->player());
    $self->_set_clan($clan);

  #--- add scoring entry to new holder

    my $se_player = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { nach => scalar(@{$game->achievements}) },
      when   => $game->endtime(),
    );

    my $se_clan = new TNNT::ScoringEntry(
      trophy => 'clan-' . $self->name(),
      games  => [ $game ],
      data   => { nach => scalar(@{$game->achievements}) },
      when   => $game->endtime(),
    );

    $game->player()->add_score($se_player);
    $game->add_score($se_player);
    $clan->add_score($se_clan) if $clan;

  #--- store new max value

    $self->_set_maxach(scalar(@{$game->achievements}));

  }

}



sub finish
{
}



#=============================================================================

1;
