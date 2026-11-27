#!/bin/sh
# stats.sh <state-repo-dir> — lifetime stats baseline for the question HUD.
# Counts closes by status from savepoint.md and the current knowledge
# state from recall.md (items, stages, latest qualities), template comment
# blocks excluded. CRLF line endings and trailing spaces are tolerated. Emits `key: value` lines; the session line is maintained
# conversationally on top of this baseline. Counting is deliberately here,
# not model-side: the HUD's lifetime numbers must not drift between sessions.
set -eu
dir=${1:?usage: stats.sh <state-repo-dir>}
# A wrong path must not look like a repository with no history.
[ -d "$dir" ] || { echo "error: not a directory: $dir" >&2; exit 1; }
w="$dir/savepoint.md"
r="$dir/recall.md"

# Attempt-level closes by heading status. `open` and `pending-evaluation`
# are provisional, not closes; `amended` corrects an existing close rather
# than adding one. All three are reported separately.
if [ -f "$w" ]; then
  awk '
    { sub(/[ \t\r]+$/, "") }
    /<!--/ { c = 1 } /-->/ { c = 0; next }
    !c && /^## q[0-9]+ — / {
      s = $0; sub(/^## q[0-9]+ — /, "", s); sub(/ @ .*/, "", s)
      if (s == "open") open++
      else if (s == "amended") amended++
      else if (s ~ /^pending-evaluation/) pending++
      else { closes++; n[s]++ }
    }
    END {
      printf "closes: %d\n", closes
      for (s in n) printf "closes_%s: %d\n", s, n[s]
      printf "open: %d\npending: %d\namended: %d\n", open, pending, amended
    }
  ' "$w"
else
  echo "closes: 0"; echo "open: 0"; echo "pending: 0"; echo "amended: 0"
fi

# Current knowledge state across recall items.
if [ -f "$r" ]; then
  awk '
    { sub(/[ \t\r]+$/, "") }
    /<!--/ { c = 1 } /-->/ { c = 0; next }
    !c && /^## q[0-9]+/ { items++ }
    !c && /^[[:space:]]*([-*][[:space:]])?stage: [0-7]$/ { s = $NF; stage[s]++ }
    !c && /^[[:space:]]*([-*][[:space:]])?last_quality: / { quality[$NF]++ }
    !c && /^[[:space:]]*([-*][[:space:]])?last_assisted: true$/ { tainted++ }
    END {
      printf "items: %d\n", items
      for (s = 0; s <= 3; s++) printf "stage%d: %d\n", s, stage[s]
      # Stages 4-7 exist only under a custom recall_intervals list longer than four.
      for (s = 4; s <= 7; s++) if (stage[s]) printf "stage%d: %d\n", s, stage[s]
      for (q in quality) printf "quality_%s: %d\n", q, quality[q]
      printf "tainted: %d\n", tainted
    }
  ' "$r"
else
  echo "items: 0"
fi
