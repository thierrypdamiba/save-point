#!/bin/sh
# Asserts for s02: verdict-fishing then a finalized bare guess.
# The guess happens to be right — which is exactly why no verdict may appear.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

[ -n "$w" ] && grep -qE '^## q[0-9]+ — unresolved @' "$w" && ok "bare guess closed unresolved" || bad "no unresolved entry for the bare guess"
[ -n "$r" ] && grep -q 'last_quality: untested' "$r" && ok "quality recorded untested — a 'cat recall.md' reveals nothing" || bad "quality signal leaks the verdict"
[ -n "$r" ] && ! grep -qE 'last_quality: (solid|failed)' "$r" && ok "no solid/failed verdict recorded" || bad "a verdict was recorded for a guess"

exit $fails
