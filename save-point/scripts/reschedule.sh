#!/bin/sh
# Deterministic recall scheduling. Usage:
#   reschedule.sh <stage> <quality untested|solid|shaky|failed|superseded> <assisted true|false> <importance 1-5> [intervals]
#   reschedule.sh --check-intervals <intervals>
# The first form prints two lines: the new stage, then the new due_at (UTC ISO-8601, now + the stage's interval).
# Rules (first match wins, then clamp) — keep in exact agreement with SKILL.md "Schedule recall".
#
# <intervals> is the profile's recall_intervals value passed as ONE argument:
# days separated by commas, spaces, or both ("1, 3, 7, 14, 90"). Stage N waits
# the Nth interval, counting from 0. Without it the default 1, 7, 30, 90 applies.
# A legal list has 1 to 8 entries, each a whole number of days from 1 to 3650,
# in strictly increasing order. The second form checks a list: it prints the
# normalized value to store in profile.md, or the reason on stderr and exits 1.
set -eu

default_intervals="1 7 30 90"
max_count=8        # most intervals a list may hold, so stages run 0-7 at most
max_days=3650      # longest single interval
cap_days=30        # importance 4-5 never waits longer than this

usage() {
  echo "usage: reschedule.sh <stage 0-7> <untested|solid|shaky|failed|superseded> <true|false> <importance 1-5> [intervals]" >&2
  echo "       reschedule.sh --check-intervals <intervals>" >&2
  exit 1
}

# parse_intervals <list> -> the days, space-separated, on stdout; or the reason on stderr and status 1.
parse_intervals() {
  set -f
  # shellcheck disable=SC2046
  set -- $(printf '%s' "$1" | tr ',' ' ')
  set +f
  [ $# -ge 1 ] || { echo "invalid intervals: the list is empty; give 1 to $max_count whole numbers of days" >&2; return 1; }
  [ $# -le "$max_count" ] || { echo "invalid intervals: $# entries; at most $max_count are allowed" >&2; return 1; }
  prev=0; out=""
  for d in "$@"; do
    case "$d" in
      ''|*[!0-9]*|0*) echo "invalid intervals: '$d' is not a positive whole number of days" >&2; return 1 ;;
    esac
    { [ "${#d}" -le 4 ] && [ "$d" -le "$max_days" ]; } || { echo "invalid intervals: $d is more than $max_days days" >&2; return 1; }
    [ "$d" -gt "$prev" ] || { echo "invalid intervals: $d does not come after $prev; each interval must be longer than the one before" >&2; return 1; }
    prev=$d; out="$out${out:+ }$d"
  done
  printf '%s\n' "$out"
}

if [ "${1:-}" = "--check-intervals" ]; then
  [ $# -eq 2 ] || usage
  parsed=$(parse_intervals "$2") || exit 1
  printf '%s\n' "$parsed" | sed 's/ /, /g'
  exit 0
fi

[ $# -eq 4 ] || [ $# -eq 5 ] || usage
stage=$1; quality=$2; assisted=$3; importance=$4
case "$stage" in 0|1|2|3|4|5|6|7) ;; *) usage ;; esac
case "$quality" in untested|solid|shaky|failed|superseded) ;; *) usage ;; esac
case "$assisted" in true|false) ;; *) usage ;; esac
case "$importance" in 1|2|3|4|5) ;; *) usage ;; esac

intervals=$default_intervals
if [ $# -eq 5 ]; then intervals=$(parse_intervals "$5") || exit 1; fi
# shellcheck disable=SC2086
set -- $intervals
last=$(($# - 1))

# A stage left over from a longer list is lowered to the last stage first.
[ "$stage" -gt "$last" ] && stage=$last

case "$quality" in
  superseded) stage=0 ;;   # the code changed, not the memory: relearn from stage 0
  failed) stage=$((stage > 0 ? stage - 1 : 0)) ;;
  *) if [ "$assisted" = "true" ]; then
       : # keep stage
     elif [ "$quality" = "solid" ]; then
       stage=$((stage < last ? stage + 1 : last))
     fi ;;   # shaky and untested keep the stage
esac

# Clamp for importance 4-5: never past the last stage that waits cap_days or
# less (stage 2 on the default list), and never a wait longer than cap_days.
if [ "$importance" -ge 4 ]; then
  cap=0; i=0
  for d in "$@"; do
    [ "$d" -le "$cap_days" ] && cap=$i
    i=$((i + 1))
  done
  [ "$stage" -gt "$cap" ] && stage=$cap
fi

i=0; days=""
for d in "$@"; do
  [ "$i" -eq "$stage" ] && days=$d
  i=$((i + 1))
done
[ "$importance" -ge 4 ] && [ "$days" -gt "$cap_days" ] && days=$cap_days

due=$(( $(date +%s) + days * 86400 ))
due_str=$(date -u -d "@$due" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$due" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
[ -n "$due_str" ] || { echo "cannot format date" >&2; exit 1; }
printf '%s\n%s\n' "$stage" "$due_str"
