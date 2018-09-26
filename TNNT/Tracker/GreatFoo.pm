#!/usr/bin/env perl

#=============================================================================
# Tracker for the Great Race/Role and Lesser Race/Role, both for individual
# players and clans.
#=============================================================================

package TNNT::Tracker::GreatFoo;

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
# Return player tracking entry. If it doesn't exist yet, new one is created
# and returned.
#-----------------------------------------------------------------------------

sub _ptrack
{
  my ($self, $player) = @_;

  if(!exists $self->_player_track()->{$player->name()}) {
    $self->_player_track()->{$player->name()} = {};
  }

  return $self->_player_track()->{$player->name()};
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

  #--- initialize player tracking

  my $ptrk = $self->_ptrack($player);

  if(!%$ptrk) {
    for my $the ('great', 'lesser' ) {
      for my $foo ('race', 'role') {
        my $the_foo = "$the$foo";

        # iterate over all combinatins of race-align or role-align defined in the
        # configuration. $rr stands for 'race or role'; note that great and lesser
        # foo have the same allowed combinations, that's why only 'greatfoo' are
        # defined in configuration

        for my $rr (keys %{$cfg->{'nethack'}{"great$foo"}}) {

        # create MultiSet tracking instance, with an embedded callback to create
        # scoring entry when the MultiSet flips to achieve state; note, that we
        # need to set a 'loose' mode of the MultiSet instance so that irrelevant
        # input is ignored instead of failing

          $ptrk->{$the_foo}{$rr} = TNNT::Tracker::MultiSet->new_sets(
            $rr => $cfg->{'nethack'}{"great$foo"}{$rr},
            sub {
              # score player
              $player->add_score(TNNT::ScoringEntry->new(
                trophy => $the_foo . ':' . lc($rr),
                game => [ $_[0] ],
                when => $_[0]->endtime()
              ));
              # score player's clan
              if(
                $clan
                &&
                !exists $self->_clan_track()->{$clan->n()}{$the_foo}{$rr}
              ) {
                $clan->add_score(TNNT::ScoringEntry->new(
                  trophy => 'clan-' . $the_foo . ':' . lc($rr),
                  game => [ $_[0] ],
                  when => $_[0]->endtime(),
                  data => { player_name => $player->name() }
                ));
                $self->_clan_track()->{$clan->n()}{$the_foo}{$rr} = $game;
              }
            }
          );
          $ptrk->{$the_foo}{$rr}->mode('loose');
        }
      }
    }
  }

  #--- track players

  # the same iteration as for intialization, but instead of creating MultiSet
  # instances we invoke their 'track' method; when the MultiSets go into
  # attained state, they automatically invoke callbacks we defined above to
  # create scoring entries

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

        # player-specific tracking structure

        my $ptrk = $self->_player_track->{$player->name()};

        # track role-race-align in MultiSet for greatrace; there's special case
        # for Great Human that only requires _one_ Monk ascension, not all three
        # available (Monks can be of any alignment)

        $ptrk->{$the_foo}{$rr}->track(
          $rr => sprintf(
            "%s-%s-%s",
            $game->role(),
            $game->race(),
            (($game->role() eq 'Mon' && $foo eq 'race') ? '*' : $game->align0())
          ),
          $game
        );

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



#=============================================================================

1;
