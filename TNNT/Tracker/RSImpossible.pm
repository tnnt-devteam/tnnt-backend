#!/usr/bin/env perl

#=============================================================================
# Track the Respectably-Sized Impossible trophy for both players and clans.
# tnntachive2: 0x3fff8000000000
#=============================================================================

package TNNT::Tracker::RSImpossible;

use Moo;
use TNNT::ScoringEntry;

no warnings 'portable';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'rsimpossible',
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

  #--- All required achievements

  if(
    ($game->tnntachieve2() & 0x3fff8000000000) == 0x3fff8000000000
  ) {

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
