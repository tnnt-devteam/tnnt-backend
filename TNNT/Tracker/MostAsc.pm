#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Ascensions" trophy
#=============================================================================

package TNNT::Tracker::MostAsc;

use Moo;
use TNNT::ScoringEntry;

with 'TNNT::AscensionList';



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'mostasc',
);

has player => (
  is => 'rwp',
);

has maxasc => (
  is => 'rwp',
  default => sub { 0 },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  my $player = $game->player();

  #--- count only ascending games

  return if !$game->is_ascended();

  #--- the very first ascension

  if(!$self->player()) {
    $self->_set_maxasc(1);
    $self->_set_player($player);
    $player->add_score(
      new TNNT::ScoringEntry(
        trophy => 'mostasc',
        games => [ $game ],
        when => $game->endtime(),
      )->add_data(wins => 1)
    );
  }

  #--- current trophy holder increased their lead, just update their scoring
  #--- entry

  elsif(
    $player->name() eq $self->player()->name()
  ) {
    my $s = $player->get_score('mostasc');
    $s->games([ @{$player->ascensions()} ]);
    $s->add_data(wins => $player->count_ascensions());
  }

  #--- player got ascension, but did not get the trophy, do nothing

  elsif(
    $player->count_ascensions() < $self->maxasc()
  ) {
  }

  #--- all other cases mean rescan of the ascension list

  else {
    my $maxasc = 0;    # most ascensions on a player
    my $maxplr;        # player with most ascensions
    my $when;          # achievement time reference
    my %p;             # hash to hold player data

    # scan the ascensions list

    $self->iter_ascensions(sub {
      my $plrname = $_->name();
      if(++$p{$plrname} > $maxasc) {
        if(!$maxplr || $maxplr ne $plrname) {
          $when = $_->endtime();
        }
        $maxplr = $plrname;
        $maxasc++;
      }
    });

    # the trophy holder has not changed, just update their scoring entry

    if($self->player()->name() eq $maxplr) {
      my $s = $self->player()->get_score('mostasc');
      $s->games([ @{$self->player()->ascensions()} ]);
      $s->add_data(wins => $self->player()->count_ascensions());
    }

    # the trophy holder has changed, delete previous scoring entry and
    # create a new one

    else {
      $self->player()->remove_score('mostasc');
      $player->add_score(new TNNT::ScoringEntry(
        trophy => 'mostasc',
        games => [ @{$player->ascensions()} ],
        data => { wins => $player->count_ascensions() },
        when => $when,
      ));
      $self->_set_player($player);
    }

    # update the number of ascensions of the trophy holder

    $self->_set_maxasc($maxasc);
  }

}



sub finish
{
}



#=============================================================================

1;
