#!/bin/sh
# elapse-days.sh <days> <file ...> — test-harness helper for scenario "!!!"
# lines. Simulates the passage of <days> days by shifting every UTC ISO-8601
# timestamp in the given state files that far into the past. This is the only
# honest way to make an item due: the model cross-checks schedule fields
# against the deterministic interval math (due_at = close + interval) and
# against savepoint close timestamps, and it repairs or distrusts a due_at
# that contradicts them — we measured both failure modes. Rewinding the whole
# timeline keeps every relationship intact; the item is simply due because
# time has passed.
set -eu
days=$1; shift
[ "$days" -gt 0 ] 2>/dev/null || { echo "usage: elapse-days.sh <days> <file ...>" >&2; exit 1; }
for f in "$@"; do
  [ -f "$f" ] || continue
  for ts in $(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$f" | sort -u); do
    epoch=$(date -u -d "$ts" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$ts" +%s)
    new=$(date -u -d "@$((epoch - days * 86400))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
      || date -u -r "$((epoch - days * 86400))" +%Y-%m-%dT%H:%M:%SZ)
    sed -i.bak "s/$ts/$new/g" "$f" && rm -f "$f.bak"
  done
done
