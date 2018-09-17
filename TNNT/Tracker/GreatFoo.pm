#!/usr/bin/env perl

#=============================================================================
# Tracker for the Great Race/Role and Lesser Race/Role
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

  #--- only ascending games

  return if !$game->is_ascended;

  #--- initialize variables we're going to use

  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($game->player());
  my $cfg = TNNT::Config->instance()->config();

  #--- initialize player tracking

  my $ptrk = $self->_ptrack($player);

  if(!%$ptrk) {
    for my $foo ('race', 'role') {
      my $greatfoo = "great$foo";

      # iterate over all combinatins of race-align or role-align defined in the
      # configuration. $rr stands for 'race or role'

      for my $rr (keys %{$cfg->{'nethack'}{$greatfoo}}) {

      # create MultiSet tracking instance, with an embedded callback to create
      # scoring entry when the MultiSet flips to achieve state; note, that we
      # need to set a 'loose' mode of the MultiSet instance so that irrelevant
      # input is ignored instead of failing

        $ptrk->{$greatfoo}{$rr} = TNNT::Tracker::MultiSet->new_sets(
          $rr => $cfg->{'nethack'}{$greatfoo}{$rr},
          sub {
            $player->add_score(TNNT::ScoringEntry->new(
              trophy => $greatfoo . ':' . lc($rr),
              game => [ $game ],
              when => $game->endtime()
            ))
          }
        );
        $ptrk->{$greatfoo}{$rr}->mode('loose');
      }
    }
  }

  #--- track players

  # the same iteration as for intialization, but instead of creating MultiSet
  # instances we invoke their 'track' method; when the MultiSets go into
  # attained state, they automatically invoke callbacks we defined above to
  # create scoring entries

  for my $foo ('race', 'role') {
    my $greatfoo = "great$foo";
    for my $rr (keys %{$cfg->{'nethack'}{$greatfoo}}) {

      # player-specific tracking structure

      my $ptrk = $self->_player_track->{$player->name()};

      # track role-align in MultiSet for greatrace; there's special case for
      # Great Human that only requires _one_ Monk ascension, not all three
      # available (Monks can be of any alignment)

      if($foo eq 'race') {
        $ptrk->{$greatfoo}{$rr}->track(
          $rr => $game->role() . '-' .
          ($game->role() eq 'Mon' ? '*' : $game->align0())
        );
      }

      # track race-align in MultiSet for greatrole

      else {
        $ptrk->{$greatfoo}{$rr}->track(
          $rr => $game->race() . '-' . $game->align0()
        )
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
