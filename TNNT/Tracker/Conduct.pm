#!/usr/bin/env perl

#=============================================================================
# Tracker for conduct ascensions. This adds conduct scoring information to
# every ascended game. This information is used by the "Ascension" tracker,
# so this must be run before it.
#=============================================================================

package TNNT::Tracker::Conduct;

use Carp;
use Moo;
use TNNT::ScoringEntry;
use TNNT::Game;
use Data::Dump qw(dd);


#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'conduct',
);

has _player_track => (
  is => 'ro',
  default => sub { {} },
);

#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# Return a ref to player tracking structure.
#-----------------------------------------------------------------------------

sub _track
{
  my ($self, $subj_type) = @_;

  if($subj_type eq 'player') {
    return $self->_player_track();
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
  } else {
    croak 'Invalid argument to GreatFoo->track_data(), must be Player or Clan';
  }
}

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;
  my $cfg = TNNT::Config->instance()->config();
  my @conducts = $game->conducts();
  #--- only ascended games with conducts
  if (!$game->is_ascended() || @conducts == 0) {
    return;
  }

  # get saved semi-persistant player conduct data
  my $player = $game->player();
  my $tracker = $self->_track_data($player);

  # add latest ascension to semi-persistent list
  # & copy full list into @games
  push @{$tracker->{'condascs'}}, $game;
  my @games = @{$tracker->{'condascs'}};

  # passing @games as a ref means we can sort it in greedy_zscore()
  # as a side-effect, which is cute but is it a good idea? :>
  my @zscores = greedy_zscore(\@games, $cfg);
  for (my $i = 0; $i < @games; $i++) {
    # create a scoring entry for each game, with the $game ref
    # itself as a key for removing/updating later
    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      when => $game->endtime,
      points => 0,
      data => {
        conducts => [ $game->conducts() ],
        conducts_txt => join(' ', $game->conducts()),
        ncond => scalar($game->conducts()),
        multiplier => $zscores[$i],
        key => $games[$i]
      }
    );
    if ($game == $games[$i]) {
      $game->add_score($se);
    } else {
      $game->remove_and_add("key", $games[$i], $se);
      # the above isn't enough to actually update the scoreboard points,
      # so we additionally need to faff with the ascension score-entry
      my $asc_se = $game->get_score_by_key("asckey", $games[$i]);
      if (defined $asc_se) {
        my $base = $asc_se->{'data'}{'breakdown'}{'bpoints'};
        my $old_cpoints = $asc_se->{'data'}{'breakdown'}{'cpoints'};
        my $new_cpoints = $base * $zscores[$i];
        $asc_se->points($asc_se->points - $old_cpoints + $new_cpoints);
        #print "updated points for old game\n";
      }
    }
  }
  #--- finish

  return $self;
}

# make a hash where each conduct has a multiplier and an associated Z-factor
sub gen_conducts_zhash {
    my $cfg = shift;
    my %hash;
    
    foreach my $conduct (@{$cfg->{'conducts'}{'order'}}) {
        $hash{$conduct}{'multi'} = $cfg->{'trophies'}{"conduct:$conduct"}{'multi'};
        $hash{$conduct}{'Z'} = 1;
    }
    return %hash;
}

# return the conduct z-score for a single game, using the Z-factors provided
# in zhash. if $update is true, tick-down each Z-factor where a conduct is recorded
sub single_zscore {
    my ($game,
       $zhash,
       $update) = @_;

    my $score = 1;
    foreach my $conduct ($game->conducts()) {
        $score *= ($zhash->{$conduct}{'Z'} * ($zhash->{$conduct}{'multi'} - 1)) + 1;
        if ($update) {
            $zhash->{$conduct}{'Z'} = 1/(1/$zhash->{$conduct}{'Z'} + 1);
        }
    }
    return $score;
}

sub greedy_zscore {
    my ($games, $cfg) = @_;
    my %zhash = gen_conducts_zhash($cfg);
    my @zscores;

    for (my $opt_index = 0; $opt_index < @$games; $opt_index++) {
        my $best = 0;
        my $best_index = $opt_index;
        for (my $test_index = $opt_index; $test_index < @$games; $test_index++) {
            my $test = single_zscore($games->[$test_index], \%zhash, 0);
            if ($test > $best) {
                $best = $test;
                $best_index = $test_index;
            }
        }

        # move the best game to the top of the list,
        # if it is not already there
        if ($opt_index != $best_index) {
            my $tmp = $games->[$opt_index];
            $games->[$opt_index] = $games->[$best_index];
            $games->[$best_index] = $tmp;
        }

        # compute zscore again for this game, this
        # time save the value and update the zhash
        push @zscores, single_zscore($games->[$opt_index], \%zhash, 1);
    }

    return @zscores;
}



sub finish
{
}



#=============================================================================

1;
