#!/usr/bin/env perl

#=============================================================================
# Tracker for the "First Ascension" trophy (both individual players and
# clans).
#=============================================================================

package TNNT::Tracker::FirstAsc;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'firstasc',
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



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player->name());

  #--- if the game is ascended and its endtime is lower than the current's
  #--- first ascension's endtime, or there is not current ascension, record it

  if(
    $game->is_ascended()
    && (
      !$self->game()
      || $game->endtime() < $self->game()->endtime()
    )
  ) {

    #--- remove scoring entry from previous holder (if any)

    if($self->player()) {
      $self->player()->remove_score('firstasc');
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
    $self->_set_clan($clan) if $clan;

    #--- add scoring entry to new holder

    my $se_player = new TNNT::ScoringEntry(
      trophy => 'firstasc',
      games => [ $game ],
      when => $game->endtime(),
    );

    my $se_clan = new TNNT::ScoringEntry(
      trophy => 'clan-firstasc',
      games => [ $game ],
      when => $game->endtime(),
    );

    $game->player()->add_score($se_player);
    $game->add_score($se_player);
    $clan->add_score($se_clan) if $clan;
  }

  return $self;
}



sub finish
{
}



#=============================================================================

1;
