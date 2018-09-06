#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions.
#=============================================================================

package TNNT::Tracker::Conduct;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'conduct',
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

  #--- only ascended games

  return if !$game->is_ascended();

  #--- get summary score for conducts

  my $cfg = TNNT::Config->instance()->config();
  my $sum_pts = 0;
  foreach my $conduct ($game->conducts()) {
    $sum_pts += $cfg->{'trophies'}{"conduct:$conduct"}{'points'};
  }

  #--- create scoring entry

  my $se = new TNNT::ScoringEntry(
    trophy => $self->name(),
    games => [ $game ],
    when => $game->endtime(),
    points => $sum_pts,
    data => {
      conducts => [ $game->conducts() ],
      conducts_txt => join(' ', $game->conducts()),
      ncond => scalar($game->conducts()),
    }
  );

  $game->player()->add_score($se);
  $game->add_score($se);

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
