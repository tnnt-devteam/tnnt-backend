#!/bin/bash
# Given a path to the root of the TNNT game source, output JSON to stdout
# containing all of the TNNT achievement names, descriptions, and xlogfile
# fields/bits in a scoreboard-ready format.
# Only includes achievements which are tracked by a single bit in a
# tnntachieveX field in the xlogfile.
# Does NOT include any achievements which are the combination of two or more
# bits, or any achievements tracked by the vanilla "achieve" field.

if [ -z $1 ]; then
  echo Usage: script /path/to/tnnt
  exit 1
fi

if [ ! -e $1 ]; then
  echo That path does not exist.
fi

# Embedded Awk script that transforms the achievement names and descriptions
# given as tab-separated lines of input into config.json-ready format.
# May break on 32-bit systems; the tnntachieveX are intended to be in 64-bit
# notation and this just relies on left-shifting 1 up to 63 bits.
read -d '' awkscript << 'EOF'
# produce commas before the line, except on the first line. This avoids us
# having to save to a temporary file and count its lines (= number of
# achievements) separately to know where the last line is.
{
  off = ((NR - 1) % 64); # compensate for NR starting at 1 rather than 0
  X = ((NR - 1) - off) / 64;
  hex = lshift(1, off);
  # note $3 is just either }, or }
  printf "\\"ach%d\\": { \\"tnntachieve%d\\": \\"0x%x\\", \\"title\\": \\"%s\\", \\"descr\\": \\"%s\\" %s\\n", NR, X, hex, $1, $2, $3;
}
EOF

# wrap in { ... } so the whole output is a single valid JSON object
echo '{'

# Grab the achievements array and chop off the end lines which aren't the
# achievement names
# First line: grab the relevant part of decl.c and chop off the start and end
# lines which aren't actually data values.
# Second line: strip C syntax and transform into tab-separated strings.
# Third line: apply awk script to turn it into JSON.
sed -n '/tnnt_achievements\[/,/^};$/ p' $1/src/decl.c | head -n -1 | tail -n +2 \
  | sed -e 's/^ *{//' -e 's/", \?/"\t/' -e 's/"//g' -e 's/\}/\t\}/' \
  | awk -F'\t' "$awkscript" #\
  # | sed "s/\'/\"/g"

echo '}'
