#!/usr/bin/env perl

#=============================================================================
# Tracker for the Great Race/Role and Lesser Race/Role, both for individual
# players and clans.
#=============================================================================

package TNNT::Tracker::GreatFoo;

use Carp;
use Moo;
use TNNT::ScoringEntry;
use TNNT::Tracker::MultiSet;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'greatfoo',
);

has _player_track => (
  is => 'ro',
  default => sub { {} },
);

has _clan_track => (
  is => 'ro',
  default => sub { {} },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return a ref to player or clan tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
  } elsif($subj_type eq 'clan') {
    return $self->_clan_track();
  }

  croak "Invalid argument to GreatFoo->_track($subj_type)";
}


#-----------------------------------------------------------------------------
# Return player/clan tracking entry. If it doesn't exist yet, new one is
# created and returned. The argument must be an instance of Player or Clan.
#-----------------------------------------------------------------------------

sub _track_data
{
  my ($self, $subj) = @_;

  if($subj->isa('TNNT::Player')) {
    if(!exists $self->_player_track()->{$subj->name()}) {
      return $self->_player_track()->{$subj->name()} = {};
    } else {
      return $self->_player_track()->{$subj->name()};
    }
  } elsif($subj->isa('TNNT::Clan')) {
    if(!exists $self->_clan_track()->{$subj->n()}) {
      return $self->_clan_track()->{$subj->n()} = {};
    } else {
      return $self->_clan_track()->{$subj->n()};
    }
  } else {
    croak 'Invalid argument to GreatFoo->track_data(), must be Player or Clan';
  }
}


#-----------------------------------------------------------------------------
# Process single game
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;

  #--- initialize variables we're going to use

  my $player = $game->player();
  my $clan = $player->clan();
  my $cfg = TNNT::Config->instance()->config();

  #--- initialize player/clan tracking

  # The following code with its nested four levels deep for loops sets up
  # a MultiSet instance for each player/clan and trophy. It also sets up
  # a callback that is invoked when the MultiSet tracker achieves the
  # 'fullfilled' state. This callback creates the scoring entries and adds
  # player/clan to list of trophy holders.

  for my $subj ($player, $clan) {

    # this weeds out games that are non-clan games (ie. player is not a member
    # of a clan

    next if !$subj;

    # get the data structure that will be used to hold tracking data

    my $trk = $self->_track_data($subj);

    if(!%$trk) {
      for my $the ('great', 'lesser' ) {
        for my $foo ('race', 'role') {
          my $the_foo = "$the$foo";

          # iterate over all combinatins of race-align or role-align defined in
          # the configuration. $rr stands for 'race or role'; note that great
          # and lesser foo have the same allowed combinations, that's why only
          # 'greatfoo' are defined in configuration

          for my $rr (keys %{$cfg->{'nethack'}{"great$foo"}}) {

          # get trophy name (clans get the "clan-" prefix)

            my $trophy_name = $the_foo . ':' . lc($rr);
            if($subj->isa('TNNT::Clan')) {
              $trophy_name = 'clan-' . $trophy_name;
            }

          # create MultiSet tracking instance, with an embedded callback to
          # create scoring entry when the MultiSet flips to achieve state;
          # note, that we need to set 'loose' mode of the MultiSet instance so
          # that irrelevant input is ignored instead of failing

            $trk->{$the_foo}{$rr} = TNNT::Tracker::MultiSet->new_sets(
              $rr => $cfg->{'nethack'}{"great$foo"}{$rr},
              sub {
                # score player
                $subj->add_score(TNNT::ScoringEntry->new(
                  trophy => $trophy_name,
                  game => [ $_[0] ],
                  when => $_[0]->endtime()
                ));
              }
            );
            $trk->{$the_foo}{$rr}->mode('loose');
          }
        }
      }
    }
  }

  #--- track players/clans

  # the same iteration as for intialization, but here we invoke their 'track'
  # method; this is all we need to do, because the callbacks will we defined
  # above will do all the work when the MultiSet trackers trigger

  for my $subj ($player, $clan) {

    # do nothing for non-clan games (ie. games by players who are not members
    # of any clan)

    next if !$subj;

    for my $the ('great', 'lesser') {

      # GreatFoo needs the game to be ascended

      next if $the eq 'great' && !$game->is_ascended();

      # LesserFoo needs the game to achieve Sokoban and Mines' End luckstone

      next if
        $the eq 'lesser'
        && !$game->has_achievement('sokoban', 'meluckstone');

      for my $foo ('race', 'role') {
        my $the_foo = "$the$foo";
        for my $rr (keys %{$cfg->{'nethack'}{"great$foo"}}) {

          # get the tracking data

          my $trk = $self->_track_data($subj);

          # track role-race-align in MultiSet for greatrace; there's special
          # case for Great Human that only requires _one_ Monk ascension, not
          # all three available (Monks can be of any alignment)

          $trk->{$the_foo}{$rr}->track(
            $rr => sprintf(
              "%s-%s-%s",
              $game->role(),
              $game->race(),
              (
                ($game->role() eq 'Mon' && $foo eq 'race')
                ? '*' : $game->align0()
              )
            ),
            $game
          );

        }
      }
    }
  }

}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
}


#-----------------------------------------------------------------------------
# Coalesce and export trophy data
#-----------------------------------------------------------------------------

sub export
{
  my ($self) = @_;
  my $cfg = TNNT::Config->instance()->config();

  my %subjects;

  foreach my $subj_type ('player', 'clan') {
    my $trk = $self->_track($subj_type);
    foreach my $subj_id (keys %$trk) {
      my $strk = $trk->{$subj_id};
      for my $the ('great', 'lesser' ) {
        for my $foo ('race', 'role') {
          my $the_foo = "$the$foo";
          for my $rr (keys %{$cfg->{'nethack'}{"great$foo"}}) {
            if($strk->{$the_foo}{$rr}->track()) {
              push(
                @{$subjects{"${subj_type}s"}{"$the_foo:" . lc($rr)}},
                $subj_id
              );
            }
          }
        }
      }
    }
  }

  return ($subjects{'players'}, $subjects{'clans'});
}



#=============================================================================

1;
