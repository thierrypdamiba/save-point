#!/bin/sh
# Checks stats.sh on LF and CRLF state files.
# Run from anywhere: sh scripts/test-stats.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
d=$(mktemp -d)
printf -- '## q001 — unaided @ 2026-01-01T00:00:00Z\n## q001 — amended @ 2026-01-02T00:00:00Z\n## q002 — pending-evaluation (unaided) @ 2026-01-03T00:00:00Z\n' > "$d/savepoint.md"
printf -- '## q001\n- stage: 1\n- last_quality: solid\n- last_assisted: false\n' > "$d/recall.md"
out=$(sh save-point/scripts/stats.sh "$d")
echo "$out" | grep -qx 'closes: 1' || { echo "FAIL closes"; echo "$out"; exit 1; }
echo "$out" | grep -qx 'amended: 1' || { echo "FAIL amended"; echo "$out"; exit 1; }
echo "$out" | grep -qx 'pending: 1' || { echo "FAIL pending"; echo "$out"; exit 1; }
echo "$out" | grep -qx 'items: 1' || { echo "FAIL items"; echo "$out"; exit 1; }
echo "$out" | grep -qx 'stage1: 1' || { echo "FAIL stage"; echo "$out"; exit 1; }
sh save-point/scripts/stats.sh "$(mktemp -d)" | grep -qx 'closes: 0'
if echo "$out" | grep -q '^stage[4-7]:'; then echo "FAIL unused high stage printed"; echo "$out"; exit 1; fi
printf -- '## q002\n- stage: 4\n- last_quality: solid\n- last_assisted: false\n' >> "$d/recall.md"
sh save-point/scripts/stats.sh "$d" | grep -qx 'stage4: 1' || { echo "FAIL stage above 3 not counted"; exit 1; }

d=$(mktemp -d)
printf -- '## q1 \342\200\224 solid @ 2026-01-01\r\n## q2 \342\200\224 failed\r\n' > "$d/savepoint.md"
printf -- '## q1\r\n- stage: 2\r\n- last_quality: solid\r\n- last_assisted: true\r\n' > "$d/recall.md"
out=$(sh save-point/scripts/stats.sh "$d")
for l in 'closes: 2' 'closes_failed: 1' 'closes_solid: 1' 'stage2: 1' 'quality_solid: 1' 'tainted: 1'; do
  echo "$out" | grep -qx "$l" || { echo "FAIL CRLF: missing '$l'"; echo "$out" | cat -A; exit 1; }
done

# A heading that ends in an HTML comment still counts. A heading inside a
# comment block does not. One-line comments do not hide what follows.
d=$(mktemp -d)
printf -- '## q1 \342\200\224 solid @ d\n## q2 \342\200\224 solid @ d <!-- note -->\n<!-- one line -->\n## q3 \342\200\224 solid @ d\n<!--\n## q4 \342\200\224 solid @ d\n-->\n## q5 \342\200\224 open @ d\n' > "$d/savepoint.md"
out=$(sh save-point/scripts/stats.sh "$d")
for l in 'closes: 3' 'closes_solid: 3' 'open: 1'; do
  echo "$out" | grep -qx "$l" || { echo "FAIL comment heading: missing '$l'"; echo "$out"; exit 1; }
done

# A missing directory is an error, not a quiet block of zeros.
if out=$(sh save-point/scripts/stats.sh "$d/no-such-dir" 2>"$d/err"); then echo "FAIL missing dir exited 0"; exit 1; fi
[ -z "$out" ] || { echo "FAIL missing dir printed stdout"; exit 1; }
grep -q 'not a directory' "$d/err" || { echo "FAIL missing dir message"; cat "$d/err"; exit 1; }

# A field a person annotated by hand still counts. Before the fix, stage 2 was
# missed and the quality was counted under the word "note".
d=$(mktemp -d)
printf -- '## q1\n- stage: 2 # note\n- last_quality: solid # note\n- last_assisted: true  # x\n' > "$d/recall.md"
out=$(sh save-point/scripts/stats.sh "$d")
for l in 'items: 1' 'stage2: 1' 'quality_solid: 1' 'tainted: 1'; do
  echo "$out" | grep -qx "$l" || { echo "FAIL trailing comment: missing '$l'"; echo "$out"; exit 1; }
done
if echo "$out" | grep -q 'quality_note'; then echo "FAIL comment text counted as a quality"; exit 1; fi
