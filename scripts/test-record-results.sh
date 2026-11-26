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
pass_if() { msg=$1; shift; run=$((run+1)); if "$@"; then ok=$((ok+1)); else echo "FAIL: $msg"; fi; }
# status_is WANT LOG [MODEL]: run the recorder, succeed if its exit status is WANT.
status_is() {
  want=$1; shift
  sh "$t/eval/record-results.sh" "$@" >/dev/null 2>&1
  got=$?
  [ "$got" -eq "$want" ]
}

printf '── a (model: m)\n── a: PASS\n── b (model: m)\n── b: FAIL\n\nmodel=m  passed=1/2\n' > "$t/good.log"
pass_if "good log recorded" status_is 0 "$t/good.log" m
pass_if "row has 1/2 and both names" grep -q '| 1/2 | a b |' "$t/eval/RESULTS.md"
pass_if "row has plugin version" grep -q '| 1.2.3 |' "$t/eval/RESULTS.md"
n=$(ls "$t/eval/results" | wc -l)
pass_if "raw log copied" test "$n" -eq 1

printf '── a: PASS\n' > "$t/partial.log"
pass_if "unfinished run rejected" status_is 1 "$t/partial.log" m
printf '── a: FAIL\n\nmodel=m  passed=1/1\n' > "$t/lie.log"
pass_if "summary that disagrees with lines rejected" status_is 1 "$t/lie.log" m
pass_if "missing model rejected" status_is 2 "$t/good.log"
rows=$(grep -c '^| 20' "$t/eval/RESULTS.md")
pass_if "rejected runs added no rows" test "$rows" -eq 1

echo "record-results tests: $ok/$run passed"
[ "$ok" -eq "$run" ]
