#!/usr/bin/env perl

#=============================================================================
# Tracker for the "All Roles/Races/Genders/Alignments/Conducts"
#=============================================================================

package TNNT::Tracker::AllCats;

use Moo;
use TNNT::Config;
use TNNT::ScoringEntry;
use TNNT::Tracker::MultiSet;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'allcats',
);

# player tracking info, hash of player names pointing to their personal
# sub-trackers

has player_track => (
  is => 'rwp',
  default => sub { {} },
);

# clan tracking info, this is hash of clan name and tracked trophy; this
# doesn't use it's own tracking instances, instead it uses the player trackers

has clan_track => (
  is => 'rwp',
  default => sub { {} },
);


#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Getter for 'player_track'.
#-----------------------------------------------------------------------------

sub ptrack
{
  my ($self, $player) = @_;

  $player = $player->name() if ref($player);

  if(exists $self->player_track()->{$player}) {
    return $self->player_track()->{$player}
  }

  return undef;
}


#-----------------------------------------------------------------------------
# Process a single game
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;

  #--- only ascended games

  return $self if !$game->is_ascended();

  #--- get more info

  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player);

  #--- if the player is not yet tracked, create the tracking structure

  my $ptrack = $self->ptrack($player);
  if(!$ptrack) {
    my $cfg = TNNT::Config->instance()->config();
    $ptrack = $self->player_track()->{ $player->name() } = {

      'roles' => TNNT::Tracker::MultiSet->new_sets(
        role => $cfg->{'nethack'}{'roles'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allroles',
              when => $game->endtime(),
            )
          );
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'roles'}
          ) {
            $self->clan_track()->{$clan->name()}{'roles'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allroles',
                when => $game->endtime(),
                data => { player => $game->name() },
              )
            );
          }
        }
      ),

      'races' => TNNT::Tracker::MultiSet->new_sets(
        race => $cfg->{'nethack'}{'races'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allraces',
              when => $game->endtime(),
            )
          );
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'races'}
          ) {
            $self->clan_track()->{$clan->name()}{'races'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allraces',
                when => $game->endtime(),
                data => { player => $game->name() },
              )
            );
          }
        }
      ),

      'genders' => TNNT::Tracker::MultiSet->new_sets(
        gender => $cfg->{'nethack'}{'genders'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allgenders',
              when => $game->endtime(),
            )
          );
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'genders'}
          ) {
            $self->clan_track()->{$clan->name()}{'genders'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allgenders',
                when => $game->endtime(),
                data => { player => $game->name() },
              )
            );
          }
        }
      ),

      'aligns' => TNNT::Tracker::MultiSet->new_sets(
        align => $cfg->{'nethack'}{'aligns'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allaligns',
              when => $game->endtime(),
            )
          );
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'aligns'}
          ) {
            $self->clan_track()->{$clan->name()}{'aligns'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allaligns',
                when => $game->endtime(),
                data => { player => $game->name() },
              )
            );
          }
        }
      ),

      'conducts' => TNNT::Tracker::MultiSet->new_sets(
        conduct => $cfg->{'conducts'}{'order'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allconducts',
              when => $game->endtime(),
            )
          );
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'conducts'}
          ) {
            $self->clan_track()->{$clan->name()}{'conducts'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allconducts',
                when => $game->endtime(),
                data => { player => $game->name() },
              )
            );
          }
        }
      ),

    };
  }

  #--- perform the tracking

  $ptrack->{'roles'}->track(role => $game->role());
  $ptrack->{'races'}->track(race => $game->race());
  $ptrack->{'genders'}->track(gender => $game->gender0());
  $ptrack->{'aligns'}->track(align => $game->align0());
  $ptrack->{'conducts'}->track(conduct => [ $game->conducts() ]);

  #--- finish

  return $self;
}


#-----------------------------------------------------------------------------
# Tracker cleanup
#-----------------------------------------------------------------------------

sub finish
{
  my ($self) = @_;

  $self->_set_player_track(undef);
  return $self;
}



#=============================================================================

1;
