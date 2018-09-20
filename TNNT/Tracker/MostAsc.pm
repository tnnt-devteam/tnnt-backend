#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Ascensions" trophy (both individual players and
# clans). One slight difference in this tracker is that it doesn't attach
# attach scoring entries to games.
#=============================================================================

package TNNT::Tracker::MostAsc;

use Moo;
use TNNT::ScoringEntry;



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

has clan => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clan = $player->clan();

  #--- count only ascending games

  return if !$game->is_ascended();

  #--- prepare scoring entries

  my $se_player = new TNNT::ScoringEntry(
    trophy => $self->name(),
    games => [ $game ],
    when => $game->endtime(),
  );

  my $se_clan = new TNNT::ScoringEntry(
    trophy => 'clan-' . $self->name(),
    games => [ $game ],
    when => $game->endtime(),
  );

  #--- the very first ascension

  if(!$self->player()) {
    $self->_set_player($player);
    $self->_set_clan($clan) if $clan;
    $player->add_score($se_player->add_data(wins =>1));
    $clan->add_score($se_clan->add_data(wins => 1)) if $clan;
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

  #--- another player overtook the current holder

  elsif(
    $player->count_ascensions() > $self->player()->count_ascensions()
  ) {

    # remove scoring entries from previous holders
    $self->player()->remove_score($self->name());
    if($self->clan()) {
      $self->clan()->remove_score('clan-' . $self->name());
    }

    # set tracker state
    $self->_set_player($player);
    $self->_set_clan($clan);

    # add new scoring entries
    $player->add_score(
      $se_player->add_data(wins => $player->count_ascensions())
    );
    $clan->add_score(
      $se_clan->add_data(wins => $player->count_ascensions())
    ) if $clan;
  }

  return $self;
}



sub finish
{
}



#=============================================================================

1;
