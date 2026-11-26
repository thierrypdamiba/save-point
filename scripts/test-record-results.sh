#!/bin/sh
# Tests for eval/record-results.sh using invented logs. These logs are test
# input only. They are never written to eval/RESULTS.md.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/eval" "$t/.claude-plugin"
cp "$here/eval/record-results.sh" "$t/eval/"
printf '{ "version": "1.2.3" }\n' > "$t/.claude-plugin/plugin.json"
run=0; ok=0
check() { run=$((run+1)); if [ "$1" = 0 ]; then ok=$((ok+1)); else echo "FAIL: $2"; fi; }

printf '── a (model: m)\n── a: PASS\n── b (model: m)\n── b: FAIL\n\nmodel=m  passed=1/2\n' > "$t/good.log"
sh "$t/eval/record-results.sh" "$t/good.log" m >/dev/null 2>&1; check $? "good log recorded"
grep -q '| 1/2 | a b |' "$t/eval/RESULTS.md"; check $? "row has 1/2 and both names"
grep -q '| 1.2.3 |' "$t/eval/RESULTS.md"; check $? "row has plugin version"
[ "$(ls "$t/eval/results" | wc -l)" -eq 1 ]; check $? "raw log copied"

printf '── a: PASS\n' > "$t/partial.log"
sh "$t/eval/record-results.sh" "$t/partial.log" m >/dev/null 2>&1; [ $? -eq 1 ]; check $? "unfinished run rejected"
printf '── a: FAIL\n\nmodel=m  passed=1/1\n' > "$t/lie.log"
sh "$t/eval/record-results.sh" "$t/lie.log" m >/dev/null 2>&1; [ $? -eq 1 ]; check $? "summary that disagrees with lines rejected"
sh "$t/eval/record-results.sh" "$t/good.log" >/dev/null 2>&1; [ $? -eq 2 ]; check $? "missing model rejected"
[ "$(grep -c '^| 20' "$t/eval/RESULTS.md")" -eq 1 ]; check $? "rejected runs added no rows"

echo "record-results tests: $ok/$run passed"
[ "$ok" -eq "$run" ]
