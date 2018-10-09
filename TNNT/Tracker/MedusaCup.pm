#!/usr/bin/env perl

#=============================================================================
# Tracker for the Medusa Cup clan trophy.
#=============================================================================

package TNNT::Tracker::MedusaCup;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-medusacup',
);

has eligible_clans => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

has topclan => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Hash of clans eligible for the trophy, ie. clans that have no ascensions.
# The hash key is clan id, the value is clan instance reference.
#-----------------------------------------------------------------------------

sub _build_eligible_clans
{
  my ($self) = @_;

  my %eligible_clans;
  TNNT::ClanList->instance()->iter_clans(sub {
    $eligible_clans{$_[0]->n()} = $_[0];
  });

  return \%eligible_clans;
}


#-----------------------------------------------------------------------------
# Process one game.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $clans = TNNT::ClanList->instance();
  my $clan = $game->player()->clan();

  #--- only clan games

  return if !$clan;

  #--- only eligible clans

  return if !exists $self->eligible_clans()->{$clan->n()};

  #--- aux function to find highest-scoring eligible clan
  # FIXME: This doesn't handle ties

  my $get_new_clan = sub {
    my @sorted =
    sort {
      $a->sum_score('!clan-medusacup') <=> $b->sum_score('!clan-medusacup')
    } # eligible clan instance refs
    map {
      $self->eligible_clans()->{$_}
    } # eligible clan ids
    keys %{$self->eligible_clans()};

    return $sorted[0];
  };

  #--- if eligible clan has ascended game, make it ineligible

  if(
    $game->is_ascended()
    && exists $self->eligible_clans()->{$clan->n()}
  ) {
    delete $self->eligible_clans()->{$clan->n()};
    if($self->topclan() && $self->topclan()->n() == $clan->n()) {
      $self->_set_topclan(undef);
      $clan->remove_score($self->name());
    }
  }

  #--- get new clan

  my $new_clan = $get_new_clan->();

  #--- if the leading clan has not changed, do nothing

  if(
    (
      $self->topclan()
      && $self->topclan()->n() == $new_clan->n()
    ) || (
      !$self->topclan()
      && !defined $new_clan
    )
  ) {
    return $self;
  }

  #--- if there's leader, remove its scoring entry

  if($self->topclan()) {
    $self->topclan()->remove_score($self->name());
  }

  #--- create new scoring entry for the new leader

  # but only if they have non-zero score; this avoids the problem where
  # multiple clans with zero score (at the start of the tournament) get
  # randomly assigned the Medusa Cup

  if(
    $new_clan && $new_clan->sum_score('!clan-medusacup')
  ) {
    $new_clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      when => $game->endtime(),
    ));
    $self->_set_topclan($new_clan);
  }

  #--- finish

  return $self;
}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
}



#=============================================================================

1;
