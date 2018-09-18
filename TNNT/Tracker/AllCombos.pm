#!/usr/bin/env perl

#=============================================================================
# Track the NetHack Master and NetHack Dominator clan trophies.
#=============================================================================

package TNNT::Tracker::AllCombos;

use Moo;
use TNNT::ScoringEntry;
use TNNT::Tracker::MultiSet;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-allcombos',
);

# clan tracking information

has _clantrk => (
  is => 'rwp',
  default => sub { {} },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($game->player());
  my $trk = $self->_clantrk();
  my $cfg = TNNT::Config->instance()->config();

  #--- only ascended clan games

  return if !$game->is_ascended() || !$clan;

  #--- create the tracking structure

  if(!exists $trk->{$clan->name()}) {
    $trk->{$clan->name()} = {

      # all combos
      'allcombos' => TNNT::Tracker::MultiSet->new_sets(
        combo => $cfg->{'nethack'}{'combos'},
        sub {
          $clan->add_score(TNNT::ScoringEntry->new(
            trophy => 'clan-allcombos',
            when => $game->endtime(),
          ));
        }
      ),

      # all combos and conducts
      'allcomcon' => TNNT::Tracker::MultiSet->new_sets(
        combo => $cfg->{'nethack'}{'combos'},
        conduct => $cfg->{'conducts'}{'order'},
        sub {
          $clan->add_score(TNNT::ScoringEntry->new(
            trophy => 'clan-allcomcon',
            when => $game->endtime(),
          ));
        }
      ),

    };
  }

  #--- track

  $trk->{$clan->name()}->{'allcombos'}->track(combo => $game->combo());
  $trk->{$clan->name()}->{'allcomcon'}->track(combo => $game->combo());

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
