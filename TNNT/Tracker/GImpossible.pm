#!/usr/bin/env perl

#=============================================================================
# Track the Great Impossible trophy for both players and clans.
#=============================================================================

package TNNT::Tracker::GImpossible;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'gimpossible',
);

# player tracking information

has _playertrk => (
  is => 'rwp',
  default => sub { {} },
);

# clan tracking information

has _clantrk => (
  is => 'rwp',
  default => sub { {} },
);

# players who have achieved this trophy

has players => (
  is => 'ro',
  default => sub { [] },
);

# clans who have achieved this trophy

has clans => (
  is => 'ro',
  default => sub { [] },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $clan = $game->player()->clan();
  my $trk = $self->_clantrk();
  my $cfg = TNNT::Config->instance()->config();

  #--- only ascended games

  return if !$game->is_ascended();

  #--- these are the 12 canonical conducts tracked by vanilla NetHack

  if(($game->conduct() & 4095) == 4095) {

    # player scoring
    if(!exists $self->_playertrk()->{$game->player()->name()}) {
      $self->_playertrk()->{$game->player()->name()} = $game;
      $game->player->add_score(TNNT::ScoringEntry->new(
        trophy => $self->name(),
        game => [ $game ],
        when => $game->endtime(),
      ));
      push(@{$self->players()}, $game->player()->name());
    }

    # clan scoring
    if($clan && !exists $self->_clantrk()->{$clan->name()}) {
      $self->_clantrk()->{$clan->name()} = $game;
      $clan->add_score(TNNT::ScoringEntry->new(
        trophy => 'clan-' . $self->name(),
        game => [ $game ],
        when => $game->endtime(),
      ));
      push(@{$self->clans()}, $clan->n());
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
