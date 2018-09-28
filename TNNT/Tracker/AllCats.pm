# #!/usr/bin/env perl

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

# this tracks players who attained one or more trophies

has players => (
  is => 'ro',
  default => sub { {
    allroles    => [],
    allraces    => [],
    allgenders  => [],
    allaligns   => [],
    allconducts => [],
  } },
);

# this tracks clans who attained one or more trophies

has clans => (
  is => 'ro',
  default => sub { {
    allroles    => [],
    allraces    => [],
    allgenders  => [],
    allaligns   => [],
    allconducts => [],
  } },
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
  my $clan = $player->clan();

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
              when => $_[0]->endtime(),
            )
          );
          push(@{$self->players()->{'allroles'}}, $player);
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'roles'}
          ) {
            $self->clan_track()->{$clan->name()}{'roles'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allroles',
                when => $_[0]->endtime(),
                data => { player => $game->name() },
              )
            );
            push(@{$self->clans()->{'allroles'}}, $clan);
          }
        }
      ),

      'races' => TNNT::Tracker::MultiSet->new_sets(
        race => $cfg->{'nethack'}{'races'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allraces',
              when => $_[0]->endtime(),
            )
          );
          push(@{$self->players()->{'allraces'}}, $player);
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'races'}
          ) {
            $self->clan_track()->{$clan->name()}{'races'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allraces',
                when => $_[0]->endtime(),
                data => { player => $game->name() },
              )
            );
            push(@{$self->clans()->{'allraces'}}, $clan);
          }
        }
      ),

      'genders' => TNNT::Tracker::MultiSet->new_sets(
        gender => $cfg->{'nethack'}{'genders'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allgenders',
              when => $_[0]->endtime(),
            )
          );
          push(@{$self->players()->{'allgenders'}}, $player);
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'genders'}
          ) {
            $self->clan_track()->{$clan->name()}{'genders'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allgenders',
                when => $_[0]->endtime(),
                data => { player => $game->name() },
              )
            );
            push(@{$self->clans()->{'allgenders'}}, $clan);
          }
        }
      ),

      'aligns' => TNNT::Tracker::MultiSet->new_sets(
        align => $cfg->{'nethack'}{'aligns'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allaligns',
              when => $_[0]->endtime(),
            )
          );
          push(@{$self->players()->{'allaligns'}}, $player);
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'aligns'}
          ) {
            $self->clan_track()->{$clan->name()}{'aligns'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allaligns',
                when => $_[0]->endtime(),
                data => { player => $game->name() },
              )
            );
            push(@{$self->clans()->{'allaligns'}}, $clan);
          }
        }
      ),

      'conducts' => TNNT::Tracker::MultiSet->new_sets(
        conduct => $cfg->{'conducts'}{'all'},
        sub {
          $player->add_score(
            TNNT::ScoringEntry->new(
              trophy => 'allconducts',
              when => $_[0]->endtime(),
            )
          );
          push(@{$self->players()->{'allconducts'}}, $player);
          if(
            $clan && !exists $self->clan_track()->{$clan->name()}{'conducts'}
          ) {
            $self->clan_track()->{$clan->name()}{'conducts'} = undef;
            $clan->add_score(
              TNNT::ScoringEntry->new(
                trophy => 'clan-allconducts',
                when => $_[0]->endtime(),
                data => { player => $game->name() },
              )
            );
            push(@{$self->clans()->{'allconducts'}}, $clan);
          }
        }
      ),

    };

    $ptrack->{'conducts'}->mode('loose');
  }

  #--- perform the tracking

  $ptrack->{'roles'}->track(role => $game->role(), $game);
  $ptrack->{'races'}->track(race => $game->race(), $game);
  $ptrack->{'genders'}->track(gender => $game->gender0(), $game);
  $ptrack->{'aligns'}->track(align => $game->align0(), $game);
  $ptrack->{'conducts'}->track(conduct => [ $game->conducts() ], $game);

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
