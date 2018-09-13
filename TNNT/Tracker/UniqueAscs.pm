#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Unique Ascensions" clan trophy.
#=============================================================================

package TNNT::Tracker::UniqueAscs;

use Moo;
use TNNT::ScoringEntry;
use TNNT::ClanList;

use Data::Dumper;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-uniqascs',
);

has _clantrk => (
  is => 'ro',
  default => sub { {} },
);

has topuniq => (
  is => 'rwp',
  default => 0,
);

has topclan => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Process a single game
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clans = TNNT::ClanList->instance();
  my $clan = $clans->find_clan($player);
  my $trk = $self->_clantrk();

  #--- only ascended clan games

  if(
    !$game->is_ascended()
    || !$clan
  ) {
    return $self;
  }

  #--- create clan tracking hash

  if(!exists $trk->{$clan}) {
    $trk->{$clan} = {};
  }

  #--- track

  my $addr = sprintf(
    "%s-%s-%s-%s",
    $game->role(),
    $game->race(),
    $game->gender0(),
    $game->align0()
  );

  if(!exists $trk->{$clan}{$addr}) {
    $trk->{$clan}{$addr} = 1;
  } else {
    $trk->{$clan}{$addr}++;
  }

  #--- the very first clan ascension is automatically a holder
  #--- of the trophy

  if(!$self->topuniq()) {
    $self->_set_topuniq(1);
    $self->_set_topclan($clan);
    $clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      game => [ $game ],
      when => $game->endtime(),
      data => { unique => 1 },
    ));
  }

  #--- new top clan

  elsif(
    $self->topuniq() < keys %{$trk->{$clan}}
    || $self->topclan()->name() ne $clan->name()
  ) {
    $self->topclan()->remove_score($self->name());
    $self->_set_topclan($clan);
    $self->_set_topuniq(scalar(keys %{$trk->{$clan}}));
    $clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      game => [ $game ],
      when => $game->endtime(),
      data => { unique => $self->topuniq() },
    ));
  }

  #--- current holder increased their lead

  elsif(
    $self->topuniq() < keys %{$trk->{$clan}}
    || $self->topclan()->name() eq $clan->name()
  ) {
    $self->_set_topuniq(scalar(keys %{$trk->{$clan}}));
    $clan->get_score($self->name())
         ->add_data(unique => $self->topuniq());
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

  return $self;
}



#=============================================================================

1;
