#!/usr/bin/env perl

#=============================================================================
# Class encapsulating streak lists (ie. multiple streaks) and their
# manipulations. Streak lists are required since player can have multiple
# streaks going at the same time.
#=============================================================================

package TNNT::StreakList;
use TNNT::Streak;

use Moo;


#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

# array of TNNT::Streak instances

has streaks => (
  is => 'rw',
  default => sub { []; },
);


#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#=============================================================================
# Return the n-th streak
#=============================================================================

sub streak
{
  my ($self, $n) = @_;

  return $self->streaks()->[$n];
}



#=============================================================================
# Return number of streaks.
#=============================================================================

sub count_streaks
{
  my ($self) = @_;

  return scalar(@{$self->streaks()});
}



#=============================================================================
# Find eligible streaks. Eligible streaks are those whose last game ends
# before the start of the game supplied as argument. The returned result is
# a list of indexes into the list of streaks (the 'streaks' attribute) ordered
# by their length (descending).
#=============================================================================

sub find_eligible
{
  my ($self, $game) = @_;
  my @eligible;

  #--- find eligible streaks

  for(my $i = 0; $i < $self->count_streaks(); $i++) {
    if($self->streak($i)->last_game()->endtime() < $game->starttime()) {
      push(@eligible, $i);
    }
  }

  #--- sort the result by streak length

  # sorting of eligible streaks by length causes the longest eligible streak
  # to be extended in cases where more than one streak exists; such cases
  # should be fairly uncommon

  @eligible = sort {
    $self->streak($b)->count_games()
    <=>
    $self->streak($a)->count_games()
  } @eligible;

  return @eligible;
}



#=============================================================================
# Close streaks reference by their index. Closing means removing the streaks
# from the list. If the list of indexes is empty, all streaks are closed.
# Callback with a list of streak games is invoked for each closed streak of
# length 2 or longer.
#=============================================================================

sub close
{
  my ($self, $cb, $streak, $tracker) = splice(@_, 0, 4);
  my @streaks = splice(@_);
  my @pruned;

  # iterate over all streaks in this instance
  for(my $i = 0; $i < @{$self->streaks()}; $i++) {

    # handle two distinct cases:
    # a) no streaks are passed as an argument or the current streak is
    #    in the list of streaks in the argument (IF block)
    # b) streaks are passed as an argument and the current streak is
    #    not in that list (ELSE block)
    if(
      !@streaks
      || (grep { $_ == $i } @streaks)
    ) {
      # if the streak length is 2 or more, invoke the callback (presumably to
      # create one or more scoring entries)
      if($cb && $self->streak($i)->count_games() > 1) {
        $cb->($streak, $tracker, $self->streak($i));
      }
    } else {
      # if the current iteration streak is not closed, move it into the list
      # of streaks that were not closed, which will then become the new streak
      # list
      push(@pruned, $self->streak($i));
    }
  }

  $self->streaks(\@pruned);
}



#=============================================================================
# Process a game, creating, extending and closing streaks as required. When
# a streak of length 2 or longer is closed, callback 1 is invoked with a list
# of games that form the streak. Callback 2 is invoked for every game that
# forms a streak when it's added (though not on the first game).
#=============================================================================

sub add_game
{
  my ($self,
      $game,
      $streak,    # streak tracker ref, needed for the close callback
      $player,
      $tracker,   # need this as the callbacks can't access the _track_data subroutine in Streak.pm
      $cb1,
      $cb2) = @_;

  #--- find eligible streaks

  my @eligible = $self->find_eligible($game);

  #--- if no eligible streak exists and the game is ascended, create
  #--- a new streak

  if(!@eligible && $game->is_ascended()) {
    my $n = $self->count_streaks();
    my $streak = $self->streaks()->[$n] = new TNNT::Streak();
    $streak->add_game($game);
  }

  #--- if eligible streak exists and the game is ascended, extend
  #--- the first eligible streak and close all the others

  elsif(@eligible && $game->is_ascended()) {
    my $top_streak = shift @eligible;
    $self->streak($top_streak)->add_game($game);
    if($cb2) { $cb2->($game, $player, $tracker, $self->streak($top_streak)->count_games()-1); }
    $self->close($cb1, $streak, $tracker, @eligible) if @eligible;
  }

  #--- if eligible streak exists and the game is not ascended
  #--- break all eligible streaks

  elsif(@eligible && !$game->is_ascended()) {
    $self->close($cb1, $streak, $tracker, @eligible);
  }
}



#=============================================================================

1;
