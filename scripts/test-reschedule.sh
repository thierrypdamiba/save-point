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
# questions_per_interruption: 0 means no unsolicited prompts, not a nudge asking for 0 questions.
printf -- '---\nquestions_per_interruption: 0\n---\n' > "$S/profile.md"
out=$(cd_run) || { echo "FAIL check-due exit with questions_per_interruption 0"; exit 1; }
test -z "$out" || { echo "FAIL questions_per_interruption 0 still nudged: $out"; exit 1; }
printf -- '---\nquestions_per_interruption: 2\n---\n' > "$S/profile.md"
out=$(cd_run); printf '%s' "$out" | grep -q 'at most 2 question' || { echo "FAIL questions_per_interruption 2 not used"; exit 1; }
# The other quiet rules: manual_only, flow mode, and a recent prompt inside the minimum gap.
printf -- '---\ninterruption_style: manual_only\n---\n' > "$S/profile.md"; rm -f "$S/scheduler.md"
chk "manual_only" quiet
rm -f "$S/profile.md"
printf -- '---\nflow_until: 2099-01-01T00:00:00Z\n---\n' > "$S/scheduler.md"
chk "flow mode on" quiet
printf -- '---\nflow_until: 2000-01-01T00:00:00Z\n---\n' > "$S/scheduler.md"
chk "flow mode expired" nudge
printf -- '---\nlast_prompt_at: %s\n---\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$S/scheduler.md"
chk "default 90m gap, just prompted" quiet
printf -- '---\nminimum_gap: 0m\n---\n' > "$S/profile.md"
chk "gap 0m, just prompted" nudge
# cross_repo_recall off: only the repository you are in may nudge. Directory x is not this one.
rm -f "$S/scheduler.md"
printf -- '---\ncross_repo_recall: off\n---\n' > "$S/profile.md"
chk "cross_repo_recall off, other repository due" quiet
G=$(mktemp -d); here=$(pwd)
( cd "$G" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m i )
id=$(cd "$G" && sh "$here/save-point/scripts/derive-repo-id.sh" . | tail -1)
mkdir -p "$S/repositories/$id"
printf -- '---\nrepository_name: mine\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/$id/recall.md"
out=$(cd "$G" && SAVE_POINT_HOME=$S sh "$here/save-point/scripts/check-due.sh")
printf '%s' "$out" | grep -q 'mine' && ! printf '%s' "$out" | grep -q '1 repository/ies (a' && printf '%s' "$out" | grep -q '1 repository' || { echo "FAIL cross_repo_recall off did not limit to this repository: $out"; exit 1; }
# A last_prompt_at in the future (clock set wrong once) must not mute the hook. A recent one still does.
printf -- '---\nrepository_name: a\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
rm -f "$S/profile.md"
printf -- '---\nlast_prompt_at: 2999-01-01T00:00:00Z\n---\n' > "$S/scheduler.md"
chk "last_prompt_at in the future" nudge
printf -- '---\nlast_prompt_at: %s\n---\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$S/scheduler.md"
chk "last_prompt_at just now" quiet
# Hand-edited profile values: YAML quotes and a trailing comment must read the same as the bare value.
rm -f "$S/scheduler.md"
for v in 'interruption_style: "manual_only"' "interruption_style: 'manual_only'" 'interruption_style: manual_only # off' \
         'daily_limit: "0"' 'daily_limit: 0 # none' 'questions_per_interruption: "0"' 'cross_repo_recall: "off"'; do
  printf -- '---\n%s\n---\n' "$v" > "$S/profile.md"
  chk "profile value: $v" quiet
done
# A near-miss style value reads as an opt-out; the two real values keep their meaning.
for v in 'manual-only' 'Manual_Only' 'off' 'bogus'; do
  printf -- '---\ninterruption_style: %s\n---\n' "$v" > "$S/profile.md"
  chk "unknown interruption_style: $v" quiet
done
printf -- '---\ninterruption_style: natural_boundaries\n---\n' > "$S/profile.md"
chk "interruption_style natural_boundaries" nudge
printf -- '---\ninterruption_style: "natural_boundaries" # default\n---\n' > "$S/profile.md"
chk "quoted natural_boundaries" nudge
printf -- '---\ninterruption_style:\n---\n' > "$S/profile.md"
chk "empty interruption_style" nudge
printf -- '---\ndaily_limit: "3" # default\nminimum_gap: "0m"\n---\n' > "$S/profile.md"
chk "quoted and commented values that allow a nudge" nudge
printf -- '---\nrepository_name: a\nnext_due_at: "2020-01-01T00:00:00Z"\n---\n' > "$S/repositories/x/recall.md"
rm -f "$S/profile.md"
chk "quoted next_due_at" nudge
# Leading zeros in hand-edited numbers must not break shell arithmetic (08 is a bad octal number in dash).
# The hook must not exit nonzero, and 08m reads as 8 minutes: a prompt 5 minutes ago is still inside the gap.
rm -f "$S/profile.md"
for v in 08m 09m 0010m 008h 000m; do
  printf -- '---\nminimum_gap: %s\n---\n' "$v" > "$S/profile.md"
  rm -f "$S/scheduler.md"
  chk "minimum_gap with leading zeros: $v" nudge
done
printf -- '---\nminimum_gap: 08m\n---\n' > "$S/profile.md"
printf -- '---\nlast_prompt_at: %s\n---\n' "$(date -u -d '@'$(( $(date +%s) - 300 )) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r $(( $(date +%s) - 300 )) +%Y-%m-%dT%H:%M:%SZ)" > "$S/scheduler.md"
chk "gap 08m, prompted 5 minutes ago" quiet
printf -- '---\ndaily_limit: 08\nquestions_per_interruption: 01\n---\n' > "$S/profile.md"
printf -- '---\nprompts_today: 07\nprompt_date: %s\n---\n' "$today" > "$S/scheduler.md"
chk "daily_limit 08, prompts_today 07" nudge
printf -- '---\nprompts_today: 08\nprompt_date: %s\n---\n' "$today" > "$S/scheduler.md"
chk "daily_limit 08, prompts_today 08" quiet
printf -- '---\ndaily_limit: 00\n---\n' > "$S/profile.md"; rm -f "$S/scheduler.md"
chk "daily_limit 00" quiet
rm -f "$S/profile.md" "$S/scheduler.md"
# The gap unit is read in any case, with spaces allowed. A prompt 100 minutes ago is inside a 3 hour gap
# and outside a 1 hour gap, whatever the case of the unit.
printf -- '---\nlast_prompt_at: %s\n---\n' "$(date -u -d '@'$(( $(date +%s) - 6000 )) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r $(( $(date +%s) - 6000 )) +%Y-%m-%dT%H:%M:%SZ)" > "$S/scheduler.md"
for v in 3h 3H "3 h" "180M" "180 m"; do
  printf -- '---\nminimum_gap: %s\n---\n' "$v" > "$S/profile.md"
  chk "minimum_gap $v, prompted 100 minutes ago" quiet
done
for v in 1h 1H "60M" "1 H"; do
  printf -- '---\nminimum_gap: %s\n---\n' "$v" > "$S/profile.md"
  chk "minimum_gap $v, prompted 100 minutes ago" nudge
done
rm -f "$S/profile.md" "$S/scheduler.md"
# A cross_repo_recall value that is not on or off reads as off. The other repository (x) must stay quiet.
rm -f "$S/profile.md"
printf -- '---\nrepository_name: a\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
for v in false no Off OFF of bogus; do
  printf -- '---\ncross_repo_recall: %s\n---\n' "$v" > "$S/profile.md"
  chk "unknown cross_repo_recall: $v" quiet
done
for v in on On ON '"on"' ''; do
  printf -- '---\ncross_repo_recall: %s\n---\n' "$v" > "$S/profile.md"
  chk "cross_repo_recall allows: [$v]" nudge
done
# A byte-order mark on profile.md or scheduler.md must not hide the opening fence. Before the fix the
# opt-out below was read as missing and the hook still nudged.
rm -f "$S/profile.md" "$S/scheduler.md"
printf -- '---\nrepository_name: a\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' > "$S/repositories/x/recall.md"
printf '\357\273\277---\r\ninterruption_style: manual_only\r\n---\r\n' > "$S/profile.md"
chk "BOM profile, manual_only" quiet
printf '\357\273\277---\ndaily_limit: 0\n---\n' > "$S/profile.md"
chk "BOM profile, daily_limit 0" quiet
rm -f "$S/profile.md"
printf '\357\273\277---\nprompt_date: %s\nprompts_today: 3\n---\n' "$(date +%Y-%m-%d)" > "$S/scheduler.md"
chk "BOM scheduler, daily cap reached" quiet
rm -f "$S/scheduler.md"
printf '\357\273\277---\ninterruption_style: natural_boundaries\n---\n' > "$S/profile.md"
chk "BOM profile, natural_boundaries" nudge
rm -f "$S/profile.md"
# The hook output must be valid JSON whatever a repository_name holds: quotes, backslashes,
# angle brackets, UTF-8 and control bytes. A broken line here would reach every prompt.
if command -v python3 >/dev/null 2>&1; then
  rm -f "$S/profile.md" "$S/scheduler.md"
  json_n=0
  for nm in 'x"y' 'back\slash' 'a\"b' '</script>' 'caf'"$(printf '\303\251')" 'ctl'"$(printf '\001\037')"'end' '{"k":1}'; do
    printf -- '---\nrepository_name: %s\nnext_due_at: 2020-01-01T00:00:00Z\n---\n' "$nm" > "$S/repositories/x/recall.md"
    out=$(cd_run) || { echo "FAIL hook exit for name: $nm"; exit 1; }
    printf '%s' "$out" | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d["hookSpecificOutput"]["additionalContext"].startswith("Save Point: recall is due")' \
      || { echo "FAIL hook output is not valid JSON for name: $nm"; echo "$out"; exit 1; }
    json_n=$((json_n + 1))
  done
  echo "hook JSON: $json_n names parsed"
else
  echo "hook JSON check not run: python3 not found"
fi
