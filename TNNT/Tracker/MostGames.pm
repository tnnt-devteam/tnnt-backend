#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Games over 1000 turns" clan trophy.
#=============================================================================

package TNNT::Tracker::MostGames;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-mostgames',
);

has _clantrk => (
  is => 'ro',
  default => sub { {} },
);

has topclan => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Process one game.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player->name());
  my $trk = $self->_clantrk();

  #--- count only clan games over 1000 turns

  return if
    !$clan
    || $game->turns() <= 1000;

  #--- track

  if(exists $trk->{$clan->name()}) {
    $trk->{$clan->name()}++;
  } else {
    $trk->{$clan->name()} = 1;
  }

  #--- the very first clan game

  if(!$self->topclan()) {
    $clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { count => 1 },
      when   => $game->endtime(),
    ));
    $self->_set_topclan($clan);
    return $self;
  }

  #--- change in the lead

  if(
    $trk->{$clan->name()} > $trk->{$self->topclan()->name()}
  ) {
    $self->topclan()->remove_score($self->name());
    $clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { count => $trk->{$clan->name()} },
      when   => $game->endtime(),
    ));
    $self->_set_topclan($clan);
  }

  #--- leading clan extended their lead

  elsif($clan->name() eq $self->topclan()->name()) {
    $clan->get_score($self->name())->add_data(
      count => $trk->{$clan->name()}
    );
  }

}



sub finish
{
}



#=============================================================================

1;
