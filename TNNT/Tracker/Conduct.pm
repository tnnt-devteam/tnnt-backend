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

has _clan_track => (
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
  } elsif($subj_type eq 'clan') {
    return $self->_clan_track();
  }

  croak "Invalid argument to Conduct->_track($subj_type)";
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

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;
  my $cfg = TNNT::Config->instance()->config();
  my @conducts = $game->conducts();
  #--- only ascended games
  if (!$game->is_ascended()) {
    return;
  }

  # get saved semi-persistant player conduct data
  my $player = $game->player();
  my $tracker = $self->_track_data($player);
  $tracker->{'asc_count'} = 0 if !defined($tracker->{'asc_count'});
  $tracker->{'asc_count'}++;
  my $key = $player->name . "-" . $tracker->{'asc_count'};
  my $clan_tracker;
  my $clan_key;
  if ($player->clan) {
    $clan_tracker = $self->_track_data($player->clan);
    # there should probably be a better way of getting the current game's index
    # in the clan ascension list, but...
    $clan_tracker->{'asc_count'} = 0 if !defined ($clan_tracker->{'asc_count'});
    $clan_tracker->{'asc_count'}++;
    $clan_key = $player->clan->name . "-" . $clan_tracker->{'asc_count'};
  }

  push @{$tracker->{'condascs'}}, { game => $game,
                                    key => $key,
                                    clan_key => $clan_key};
  my @cond_ascs = @{$tracker->{'condascs'}};

  # passing @games as a ref means we can sort it in greedy_zscore()
  # as a side-effect, which is cute but is it a good idea? :>
  my @zscores = greedy_zscore(\@cond_ascs, $cfg);
  for (my $i = 0; $i < @cond_ascs; $i++) {
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
        key => $cond_ascs[$i]->{'key'}
      }
    );
    if ($key eq $cond_ascs[$i]->{'key'}) {
      # the case for the current game is quite simple
      # i think game score is only the one entry, while
      # with player->add_score() we can retreive the previous games
      #print "$key: conduct points = ", $zscores[$i] * 50, "\n";
      $game->add_score($se);
    } else {
      # for older games we have to update stuff
      # the actual game ref is in the cond_ascs data structure
      $cond_ascs[$i]->{'game'}->remove_and_add("key", $cond_ascs[$i]->{'key'}, $se);
      
      # the above isn't enough to actually update the scoreboard points,
      # so we additionally need to faff with the ascension score-entry
      my $asc_se = $player->get_score_by_key("asckey", $cond_ascs[$i]->{'key'});
      if (defined $asc_se) {
        my $base = $asc_se->{'data'}{'breakdown'}{'bpoints'};
        my $rest = $asc_se->{'data'}{'breakdown'}{'spoints'} + $asc_se->{'data'}{'breakdown'}{'tpoints'} + $asc_se->{'data'}{'breakdown'}{'zpoints'};
        my $old_cpoints = $asc_se->{'data'}{'breakdown'}{'cpoints'};
        my $new_cpoints = int($base * $zscores[$i]);
        $asc_se->{'data'}{'breakdown'}{'cpoints'} = $new_cpoints;
        my $old_score = $asc_se->get_points();
        $asc_se->points($new_cpoints + $rest);
        #print "update ", $cond_ascs[$i]->{'key'}, " : new conduct points = ", $new_cpoints, "\n";

        # ah crap, streak points depend on conduct points and everything else of the score,
        # thus we have to also update that when a conduct score is updated FML
        # in general the code for updating prior games should be refactored somehow because atm
        # the same blocks of boilerplate appear multiple times...
        my $streak = $cond_ascs[$i]->{'game'}->get_score('streak');
        next if !$streak;
        my $streak_multi = $streak->get_data('streakmult');
        my $rest = $asc_se->{'data'}{'breakdown'}{'spoints'} + $asc_se->{'data'}{'breakdown'}{'cpoints'} + $asc_se->{'data'}{'breakdown'}{'zpoints'};
        my $streak_bonus = $rest * $streak_multi;
        $asc_se->{'data'}{'breakdown'}{'tpoints'} = $streak_bonus;
        $asc_se->points($rest + $streak_bonus);
      } else {
        warn "failed to find player score entry for game with key " . $cond_ascs[$i]->{'key'} . "\n";
      }
      if (defined $cond_ascs[$i]->{'clan_key'}) {
        # if player is a clan member we have to update the clan score entry too
        my $clan_asc_se = $player->clan->get_score_by_key("clan_asckey", $cond_ascs[$i]->{'clan_key'});
        if (defined $clan_asc_se) {
          my $base = $clan_asc_se->{'data'}{'breakdown'}{'bpoints'};
          my $rest = $clan_asc_se->{'data'}{'breakdown'}{'spoints'} + $clan_asc_se->{'data'}{'breakdown'}{'tpoints'} + $clan_asc_se->{'data'}{'breakdown'}{'zpoints'};
          my $old_cpoints = $clan_asc_se->{'data'}{'breakdown'}{'cpoints'};
          my $new_cpoints = int($base * $zscores[$i]);
          $clan_asc_se->{'data'}{'breakdown'}{'cpoints'} = $new_cpoints;
          $clan_asc_se->points($new_cpoints + $rest);

          # ah crap, streak points depend on conduct points and everything else of the score,
          # thus we have to also update that when a conduct score is updated FML
          # in general the code for updating prior games should be refactored somehow because atm
          # the same blocks of boilerplate appear multiple times...
          my $streak = $cond_ascs[$i]->{'game'}->get_score('streak');
          next if !$streak;
          my $streak_multi = $streak->get_data('streakmult');
          my $rest = $clan_asc_se->{'data'}{'breakdown'}{'spoints'}
                   + $clan_asc_se->{'data'}{'breakdown'}{'cpoints'}
                   + $clan_asc_se->{'data'}{'breakdown'}{'zpoints'};
          my $streak_bonus = $rest * $streak_multi;
          $clan_asc_se->{'data'}{'breakdown'}{'tpoints'} = $streak_bonus;
          $clan_asc_se->points($rest + $streak_bonus);
        } else {
          warn "failed to find clan score entry for game with key " . $cond_ascs[$i]->{'clan_key'} . "\n";
        }
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

    # if Zscore bonus would end up negative multiplier, return 0 instead
    if ($score < 1) {
      return 0;
    } else {
      return $score - 1;
    }
}

sub greedy_zscore {
    my ($cond_ascs, $cfg) = @_;
    my %zhash = gen_conducts_zhash($cfg);
    my @zscores;

    for (my $opt_index = 0; $opt_index < @$cond_ascs; $opt_index++) {
        my $best = 0;
        my $best_index = $opt_index;
        for (my $test_index = $opt_index; $test_index < @$cond_ascs; $test_index++) {
            my $test = single_zscore($cond_ascs->[$test_index]->{'game'}, \%zhash, 0);
            if ($test > $best) {
                $best = $test;
                $best_index = $test_index;
            }
        }

        # move the best game to the top of the list,
        # if it is not already there
        if ($opt_index != $best_index) {
            my $tmp = $cond_ascs->[$opt_index];
            $cond_ascs->[$opt_index] = $cond_ascs->[$best_index];
            $cond_ascs->[$best_index] = $tmp;
        }

        # compute zscore again for this game, this
        # time save the value and update the zhash
        push @zscores, single_zscore($cond_ascs->[$opt_index]->{'game'}, \%zhash, 1);
    }

    return @zscores;
}



sub finish
{
}



#=============================================================================

1;
