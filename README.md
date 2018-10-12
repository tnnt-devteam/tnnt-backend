# THE NEXT NOVEMBER TOURNAMENT SCOREBOARD / BACKEND

Back-end part of the /dev/null/nethack replacement
tournament. Work in progress.

## COMMAND-LINE OPTIONS

**--help**  
Display usage summary and exit.

**--json**, **--json**=*file*  
Instead of compiling templates into HTML files output JSON formatted
data on standard output or into specified file.

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

**`games`.`ascs`**  

This is a simple array of ascended games, in chronological order.
