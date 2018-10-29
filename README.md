# THE NEXT NOVEMBER TOURNAMENT SCOREBOARD / BACKEND

Back-end part of the /dev/null/nethack replacement
tournament. Work in progress.

## COMMAND-LINE OPTIONS

**--help**  
Display usage summary and exit.

**--json**, **--json**=*file*  
Output the scoreboard's internal data that are passed into templates as JSON
text file, either on output or to specified file.

**--nohtml**  
Do not compile templates into HTML. Useful when you only want to get the
JSON data.

**--coalesce**=*file*  
Merge the source xlogfiles into one unified xlogfile. This can be used by
external consumer to see the tournament as a single source.


## TEMPLATE DATA

The scoreboard collates single coherent data structure that is
passed to the Template Toolkit templates to produce final HTML
pages. Alternatively, this data structure can be output as JSON
encoded text.

Following are the top-level sections of the data

* games
* players
* clans
* trophies
* config

The detailed description of the section follows.

### games

This section has only two sub-sections: `all` and `ascs`.

**`games`.`all`**  

`games`.`all` is an array of hashes, each hash representing one game
from xlogfile(s), with the keys being the xlogfile fields with some
additional fields added by the scoreboard. The order is by value of
endtime, ascending.

`games`.`all` acts as the master games list. Every other part of the
data that refers to individual games refers to this array's numerical
index. In other words, games are referenced as integers, that are
an index to this array.

Following fields are taken from xlogfile fields with some caveats
(see below):

`name`, `points`, `role`, `race`, `gender`, `align`, `maxlvl`,
`realtime`, `deathlev`, `turns`, `starttime`, `endtime`, `death`,
`maxhp` , `hp`,

These fields are processed and not taken verbatim from xlogfile:

* `gender` and `align` are starting gender and alignments
* `starttime` and `endtime` are formatted to be human-readable

Following fields are added by the scoreboard during parsing:

* `src` is the short-name of the source server
* `clan_unique` indicates if the game is a unique ascension for
player's clan
* `achievements` is an array of player's achievements' short-names
* `dumplog` is a URL of the dumplog
* `n` is the index (sometimes useful when passing ref to the game
itself)
* `scum` indicates if the game is regarded as scummmed; scumming
criteria are defined in configuration

**`games`.`ascs`**  

This is a simple array of ascended games, in chronological order.


### players

This section lists all the player details. Players, for the purpose
of the scoreboard, are identified by their name, ie. there is no
special index. This is different from clans, which are refered
to by numerical index.

**`players`.`all`**

This is the master player "list". It's actually hash with player
names as hash keys.

Each player is a hash with following keys:

* `name` is simply player's name (the same as the key value)
* `games` is list of player's games
* `ascs` is list of player's ascensions
* `rank` is player's rank in the ordering of players in
`players`.`ordered`
* `maxlvl` is player's maximum experience level achieved
* `score` is player's summary score
* `scores` is player's scoring log (see below)
* `achievements` is list of player's achievements (this key always
exists, even if empty)
* `maxcond` is player's maximum of conducts reached in single game
(only exists for ascending players)
* `minturns` is a turncount of player's fastest gametime ascension
* `minscore` is player's minimum score for a winning game
* `highscore` is player's high score for a winning game
* `maxstreaklen` is player's longest streak's length
* `realtime` is player's fastest realtime of a winning game, in human readable
format
* `ratio` is player's ascension ratio (only exists for ascending
players)
* `streaks` is list of player's streaks, streaks are in turn lists
of streak games (only exists for players with streaks)
* `clan` is a reference to clan definition (numerical index, only
exists for players that are clan members)
* `trophies` is list of scoring entries (the same as in `scores`), but
only with actual trophies)
* `scum` is a count of scummed games, this field always exists

**`players`.`ordered`**

This is list of playernames ordered by the primary sorting criteria
(score, number of ascensions etc.).

**scoring entries**

Both players and clans have associated lists of scoring entries.
Each event that generates some points is logged in scoring list
(`scores` key in player/clan). Single scoring entry is a hash
with following keys:

* `trophy` is trophy short name like *minturns*, *ascension* etc.
(note: the entry might be for something that is not actually a trophy,
like a simple ascension); clan trophies
"clan-" prepended to them, eg. *clan-minturns*
* `when` is Unix epoch time of when the scoring entry was
issued
* `when_fmt` is human-readable time of when the scoring entry was
issued* `points` number of points the entry is issued for
* `data` is a hash of additional, trophy specific data, this can
be empty or even missing


### clans

This section details clan data and has two keys `all` and `ordered`.

**`clans`.`all`**  

List of hashes, each hash for one clan. The (numerical) index of a clan in
this array is how the clans are refered to elsewhere.

Following keys are present:

* `name` is clan's name
* `n` is clan's index value
* `players` is list of clan members
* `admins` is list of clan members with admin privilege
* `games` is list of all clan's games
* `ascs` is list of clan's ascensions
* `ratio` is clan's ascension ratio
* `unique_ascs` is a list of ascensions that are unique for the clan
* `achievements` is list of clan achievements
* `udeaths_rank` is clan's rank in the Unique Deaths competition
* `unique_deaths` is list of (death message, game) tuples; the game refers to
the game that cause the new death reason to be logged for the clan
* `scores` is clan's full scoring log (see above in **players** section)
* `trophies` is clan's trophy log (see above in **players** section), it only
lists real trophies, not things like single ascensions, individual streaks etc.
* `rank` is clan's rank in clan competition
* `score` is summary clan score
* `games1000t` is count of clan's games over 1000 turns
* `unique_ascs` is count of clan's unique (ie. non-repeating) ascensions

**`clans`.`ordered`**

List of clan indices ordered by clan scores.


### trophies

This section primarily exists to generate the Trophies page. It has two
sub-sections: `players` and `clans`. Both of these have the same structure,
so we will describe them at once.

The keys under `players` or `clans` are the trophy short words such as
*minturns*, *mostascs* or *gimpossible*. Where the trophy can only be held
by one player/clan, there's only single value. Otherwise, the value is a list
of values.

The exception here are trophies Great/Lesser Race/Role. These are under keys
`greatfoo` and `lesserfoo` and have subkeys such `greatrace:orc`,
`greatrole:hum`, `lesserrace:elf` etc.

Note, that only trophies that have been achieved are listed in the `trophies`
section.


### config

This section simply includes the entirety of config.json file, so that
templates can use configuration data when needed.
