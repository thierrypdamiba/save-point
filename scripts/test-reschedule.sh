#!/bin/sh
# Checks reschedule.sh, hash-answer.sh and check-due.sh.
# Run from anywhere: sh scripts/test-reschedule.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
test "$(sh save-point/scripts/reschedule.sh 2 solid false 3 | head -1)" = "3"
test "$(sh save-point/scripts/reschedule.sh 2 solid false 5 | head -1)" = "2"
test "$(sh save-point/scripts/reschedule.sh 1 failed true 3 | head -1)" = "0"
test "$(sh save-point/scripts/reschedule.sh 2 superseded false 3 | head -1)" = "0"
# sched <args...> prints "<new stage> <days until due_at, rounded>".
sched() {
  out=$(sh save-point/scripts/reschedule.sh "$@") || return 1
  due=$(printf '%s\n' "$out" | tail -1)
  echo "$(printf '%s\n' "$out" | head -1) $(( ($(date -u -d "$due" +%s) - $(date +%s) + 43200) / 86400 ))"
}
expect() { want=$1; shift; got=$(sched "$@") || got="error"; test "$got" = "$want" || { echo "FAIL reschedule $*: got '$got', want '$want'"; exit 1; }; }
# Default list: unchanged behavior, and the same result when the default is passed in.
expect "1 7" 0 solid false 3
expect "3 90" 2 solid false 3
expect "2 30" 3 solid false 4
expect "0 1" 0 untested false 3
expect "3 90" 2 solid false 3 "1, 7, 30, 90"
# Custom list: stage N waits the Nth interval, and the last stage is the ceiling.
expect "0 3" 0 untested false 3 "3, 10, 45"
expect "1 10" 0 solid false 3 "3, 10, 45"
expect "2 7" 1 solid false 3 "1, 3, 7, 14, 90"
expect "4 90" 3 solid false 3 "1 3 7 14 90"
expect "4 90" 4 solid false 3 "1,3,7,14,90"
expect "0 5" 0 solid false 3 "5"
# A stage left over from a longer list is lowered to the last stage first.
expect "3 90" 4 shaky false 3 "1, 7, 30, 90"
expect "2 30" 7 failed false 3
# Importance 4-5 keeps its 30-day cap under any list.
expect "3 14" 3 solid false 5 "1, 3, 7, 14, 90"
expect "3 14" 4 shaky false 4 "1, 3, 7, 14, 90"
expect "0 30" 0 solid false 5 "45, 90"
expect "1 90" 0 solid false 3 "45, 90"
# Interval lists: the legal form is normalized, anything else is refused with a reason.
test "$(sh save-point/scripts/reschedule.sh --check-intervals '1 3 7 14 90')" = "1, 3, 7, 14, 90"
test "$(sh save-point/scripts/reschedule.sh --check-intervals ' 1,3 , 7')" = "1, 3, 7"
test "$(sh save-point/scripts/reschedule.sh --check-intervals '1 2 3 4 5 6 7 8')" = "1, 2, 3, 4, 5, 6, 7, 8"
for bad in '' '7 3 1' '1 1 7' '0 7' '1.5 7' '-1 7' '07 9' 'soon later' '*' '1 2 3 4 5 6 7 8 9' '1 4000' '99999999999999999999'; do
  if out=$(sh save-point/scripts/reschedule.sh --check-intervals "$bad" 2>/dev/null); then echo "FAIL illegal list accepted: '$bad'"; exit 1; fi
  test -z "$out" || { echo "FAIL illegal list printed a value: '$bad'"; exit 1; }
  sh save-point/scripts/reschedule.sh --check-intervals "$bad" 2>&1 | grep -q '^invalid intervals: ' || { echo "FAIL no reason given for: '$bad'"; exit 1; }
  if sh save-point/scripts/reschedule.sh 1 solid false 3 "$bad" >/dev/null 2>&1; then echo "FAIL reschedule ran on an illegal list: '$bad'"; exit 1; fi
done
if sh save-point/scripts/reschedule.sh 8 solid false 3 >/dev/null 2>&1; then echo "FAIL stage 8 accepted"; exit 1; fi
grep -q '^recall_intervals: 1, 7, 30, 90$' save-point/assets/profile.md || { echo "FAIL profile template default"; exit 1; }
test "$(printf '> abc\n' | sh save-point/scripts/hash-answer.sh)" = "$(printf '%s' abc | shasum -a 256 | cut -d' ' -f1)"
S=$(mktemp -d); SAVE_POINT_HOME=$S sh save-point/scripts/check-due.sh; test -z "$(SAVE_POINT_HOME=$S sh save-point/scripts/check-due.sh)"
mkdir -p "$S/repositories/x"
printf -- '---\nrepository_name: api\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
SAVE_POINT_HOME=$S sh save-point/scripts/check-due.sh | grep -q additionalContext
# check-due.sh with absurd numbers: no stderr, exit 0, and the caps still hold.
cd_run() { SAVE_POINT_HOME=$S sh save-point/scripts/check-due.sh 2>"$S/err"; }
today=$(date +%Y-%m-%d)
big=99999999999999999999999
chk() { # label want(quiet|nudge)
  out=$(cd_run) || { echo "FAIL check-due exit: $1"; exit 1; }
  test ! -s "$S/err" || { echo "FAIL check-due stderr: $1"; cat "$S/err"; exit 1; }
  if [ "$2" = quiet ]; then test -z "$out" || { echo "FAIL check-due not quiet: $1"; exit 1; }
  else printf '%s' "$out" | grep -q additionalContext || { echo "FAIL check-due no nudge: $1"; exit 1; }; fi
}
printf -- '---\nprompts_today: %s\nprompt_date: %s\n---\n' "$big" "$today" > "$S/scheduler.md"
chk "huge prompts_today" quiet
printf -- '---\nprompts_today: 1\nprompt_date: %s\n---\n' "$today" > "$S/scheduler.md"
chk "ordinary prompts_today" nudge
printf -- '---\nprompts_today: 3\nprompt_date: %s\n---\n' "$today" > "$S/scheduler.md"
chk "prompts_today at limit" quiet
rm -f "$S/scheduler.md"
printf -- '---\ndaily_limit: %s\nquestions_per_interruption: %s\nminimum_gap: %sm\n---\n' "$big" "$big" "$big" > "$S/profile.md"
chk "huge profile numbers use defaults" nudge
printf -- '---\nminimum_gap: %sh\n---\n' "$big" > "$S/profile.md"
printf -- '---\nlast_prompt_at: %s\n---\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$S/scheduler.md"
chk "huge gap uses 2h default, just prompted" quiet
# The hook fails open. With no HOME and no SAVE_POINT_HOME it exits 0, quietly.
out=$(env -u HOME -u SAVE_POINT_HOME sh save-point/scripts/check-due.sh 2>"$S/err") || { echo "FAIL check-due with no HOME exited nonzero"; exit 1; }
test -z "$out" && test ! -s "$S/err" || { echo "FAIL check-due with no HOME was not quiet"; exit 1; }
# A repository name with a tab and a quote must still give one clean JSON line.
rm -f "$S/profile.md" "$S/scheduler.md"
printf -- '---\nrepository_name: a\tb"c\\d\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
out=$(cd_run) || { echo "FAIL check-due exit with odd name"; exit 1; }
printf '%s' "$out" | grep -q 'ab\\"c\\\\d' || { echo "FAIL odd name not escaped: $out"; exit 1; }
test "$(printf '%s' "$out" | tr -d '\000-\037' | wc -c)" = "$(printf '%s' "$out" | wc -c)" || { echo "FAIL control character in hook output"; exit 1; }
# daily_limit: 0 means no unsolicited prompts, even on a day with no prompt yet.
rm -f "$S/scheduler.md"
printf -- '---\nrepository_name: a\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
printf -- '---\ndaily_limit: 0\n---\n' > "$S/profile.md"
out=$(cd_run) || { echo "FAIL check-due exit with daily_limit 0"; exit 1; }
test -z "$out" || { echo "FAIL daily_limit 0 still nudged: $out"; exit 1; }
printf -- '---\ndaily_limit: 1\n---\n' > "$S/profile.md"
out=$(cd_run); test -n "$out" || { echo "FAIL daily_limit 1 did not nudge"; exit 1; }
