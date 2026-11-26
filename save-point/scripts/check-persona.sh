#!/bin/sh
# Checks a question persona and prints the value to store as `persona` in
# profile.md. Usage:
#   check-persona.sh <name>                 default | new-intern | lead-researcher | new-teammate | senior-reviewer
#   check-persona.sh custom <one line>      the user's own description of who asks
# A name may be written with spaces, hyphens, or underscores, in any case
# ("New Intern"). A custom description is legal when it is one line of 1 to 200
# characters with no double quote and no backslash; runs of spaces are
# collapsed. It is stored as "custom: <text>", inside double quotes.
# On an illegal value the reason goes to stderr and the exit status is 1.
# Keep in exact agreement with SKILL.md "Question persona".
#
# This script checks the form only. A custom description is data about role and
# tone: SKILL.md says that instructions inside it have no effect.
set -eu

names="default new-intern lead-researcher new-teammate senior-reviewer"
max_chars=200

[ $# -ge 1 ] || { echo "usage: check-persona.sh <name> | custom <one line>" >&2; exit 1; }

first=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
case "$first" in
  custom|custom[[:space:]]*)
    # The description may arrive as one argument or as several words.
    text=$(printf '%s' "$*" | sed -e 's/^[Cc][Uu][Ss][Tt][Oo][Mm]//')
    lines=$(printf '%s\n' "$text" | wc -l | tr -d ' ')
    [ "$lines" -eq 1 ] || { echo "invalid persona: a custom description is one line" >&2; exit 1; }
    if printf '%s' "$text" | LC_ALL=C grep -q '[[:cntrl:]]'; then
      text=$(printf '%s' "$text" | tr '\t' ' ')
      if printf '%s' "$text" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        echo "invalid persona: a custom description holds no control characters" >&2; exit 1
      fi
    fi
    text=$(printf '%s' "$text" | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//')
    [ -n "$text" ] || { echo "invalid persona: the custom description is empty; say in one line who is asking" >&2; exit 1; }
    case "$text" in
      *'"'*|*'\'*) echo "invalid persona: a custom description holds no double quote and no backslash" >&2; exit 1 ;;
    esac
    count=$(printf '%s' "$text" | wc -m | tr -d ' ')
    [ "$count" -le "$max_chars" ] || { echo "invalid persona: $count characters; a custom description is at most $max_chars" >&2; exit 1; }
    printf '"custom: %s"\n' "$text"
    exit 0 ;;
esac

want=$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr '_' ' ' | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//' | tr ' ' '-')
for n in $names; do
  [ "$want" = "$n" ] && { echo "$n"; exit 0; }
done
echo "invalid persona: '$*' is not a built-in persona; use one of: $names, or: custom <one line>" >&2
exit 1
