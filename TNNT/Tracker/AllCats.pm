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
# Getter for player/clan tracking structure.
#-----------------------------------------------------------------------------

sub track_data
{
  my ($self, $subj) = @_;

  $subj = $subj->name() if ref($subj);

  if($subj->isa('TNNT::Player')) {
    if(exists $self->player_track()->{$subj}) {
      return $self->player_track()->{$subj}
    }
  } else {
    if(exists $self->clan_track()->{$subj}) {
      return $self->clan_track()->{$subj}
    }
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
  my $cfg = TNNT::Config->instance()->config();

  #--- auxiliary function for generating trackers, takes two arguments:
  #--- 1. player or clan instance, 2. category name in singular ('conduct',
  #--- 'role' etc. ) and returns MultiSet tracker instance

  my $get_tracker = sub {
    my ($subj, $cat) = @_;

    my $trophy = "all${cat}s";
    if($subj->isa('TNNT::Clan')) {
      $trophy = 'clan-' . $trophy;
    }

    my $cat_enum = $cfg->{'nethack'}{"${cat}s"};
    if($cat eq 'conduct') {
      $cat_enum = $cfg->{'conducts'}{'all'}
    }

    return TNNT::Tracker::MultiSet->new_sets(
      $cat => $cat_enum,
      sub {
        $subj->add_score(
          TNNT::ScoringEntry->new(
            trophy => $trophy,
            when => $_[0]->endtime(),
          )
        );
        if($subj->isa('TNNT::Player')) {
          push(@{$self->players()->{"all${cat}s"}}, $subj);
        } else {
          push(@{$self->clans()->{"all${cat}s"}}, $subj);
        }
      }
    );
  };

  #--- if the player is not yet tracked, create the tracking structure

  my $ptrack = $self->track_data($player);
  if(!$ptrack) {
    $ptrack = $self->player_track()->{ $player->name() } = {
      'roles'    => $get_tracker->($player, 'role'),
      'races'    => $get_tracker->($player, 'race'),
      'genders'  => $get_tracker->($player, 'gender'),
      'aligns'   => $get_tracker->($player, 'align'),
      'conducts' => $get_tracker->($player, 'conduct'),
    };

    $ptrack->{'conducts'}->mode('loose');
  }

  #--- if the player is a clan member and the clan is not yet tracked,
  #--- create its tracking structure

  my $ctrack;
  if($clan) {
    $ctrack = $self->track_data($clan);
    if(!$ctrack) {
      $ctrack = $self->clan_track()->{ $clan->name() } = {
        'roles'    => $get_tracker->($clan, 'role'),
        'races'    => $get_tracker->($clan, 'race'),
        'genders'  => $get_tracker->($clan, 'gender'),
        'aligns'   => $get_tracker->($clan, 'align'),
        'conducts' => $get_tracker->($clan, 'conduct'),
      };

      $ctrack->{'conducts'}->mode('loose');
    }
  }

  #--- perform the tracking

  $ptrack->{'roles'}->track(role => $game->role(), $game);
  $ptrack->{'races'}->track(race => $game->race(), $game);
  $ptrack->{'genders'}->track(gender => $game->gender0(), $game);
  $ptrack->{'aligns'}->track(align => $game->align0(), $game);
  $ptrack->{'conducts'}->track(conduct => [ $game->conducts() ], $game);

  if($clan) {
    $ctrack->{'roles'}->track(role => $game->role(), $game);
    $ctrack->{'races'}->track(race => $game->race(), $game);
    $ctrack->{'genders'}->track(gender => $game->gender0(), $game);
    $ctrack->{'aligns'}->track(align => $game->align0(), $game);
    $ctrack->{'conducts'}->track(conduct => [ $game->conducts() ], $game);
  }

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
  $self->_set_clan_track(undef);
  return $self;
}



#=============================================================================

1;
