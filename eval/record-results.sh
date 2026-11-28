#!/bin/sh
# Turn the saved output of eval/run.sh into a dated row in eval/RESULTS.md.
#
# Usage: ./run.sh s01-solid-close 2>&1 | tee /tmp/run.log
#        ./record-results.sh /tmp/run.log "<model id you ran>"
#
# The raw log is copied to eval/results/ and the table row points at it, so a
# reader can check the row against the run. Only record runs that happened.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
log=${1:-}; model=${2:-}
[ -n "$log" ] && [ -f "$log" ] && [ -n "$model" ] || { echo "usage: record-results.sh <run.log> <model id>" >&2; exit 2; }

summary=$(grep -E '^model=.* passed=[0-9]+/[0-9]+$' "$log" | tail -1 || true)
[ -n "$summary" ] || { echo "error: no 'passed=N/M' summary line in $log (run did not finish)" >&2; exit 1; }
passed=$(printf '%s' "$summary" | sed 's/.*passed=\([0-9]*\)\/.*/\1/')
total=$(printf '%s' "$summary" | sed 's/.*\/\([0-9]*\)$/\1/')

# Cross-check the summary against the per-scenario lines.
pass_lines=$(grep -c '^── .*: PASS$' "$log" || true)
fail_lines=$(grep -c '^── .*: FAIL$' "$log" || true)
[ "$pass_lines" -eq "$passed" ] && [ $((pass_lines + fail_lines)) -eq "$total" ] || {
  echo "error: summary $passed/$total does not match $pass_lines PASS and $fail_lines FAIL lines" >&2; exit 1; }

names=$(grep -E '^── .*: (PASS|FAIL)$' "$log" | sed 's/^── \(.*\): \(PASS\|FAIL\)$/\1/' | tr '\n' ' ' | sed 's/ $//')
version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$here/../.claude-plugin/plugin.json" | head -1)
commit=$(git -C "$here" rev-parse --short HEAD 2>/dev/null || echo unknown)
day=$(date -u +%Y-%m-%d)
safe=$(printf '%s' "$model" | tr -c 'A-Za-z0-9._-' '_')
mkdir -p "$here/results"
dest="$here/results/$day-$safe-$commit.log"
cp "$log" "$dest"

res="$here/RESULTS.md"
if [ ! -f "$res" ]; then
  cat > "$res" <<'HDR'
# Eval results

One row per real run of `eval/run.sh`. The raw output of each run is saved in `eval/results/` and the last column names it. Rows come only from runs someone made. A scenario that did not run is not listed as passed.

A pass here means the assert script for that scenario passed on that run. It is a count from one run, not a rate. Model replies vary between runs.

| Date (UTC) | Model | Save Point version | Commit | Passed | Scenarios run | Raw output |
| --- | --- | --- | --- | --- | --- | --- |
HDR
fi
echo "| $day | $model | $version | $commit | $passed/$total | $names | results/$(basename "$dest") |" >> "$res"
echo "recorded $passed/$total in $res"
