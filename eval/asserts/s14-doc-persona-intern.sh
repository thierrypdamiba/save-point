#!/bin/sh
# Asserts for s14: the new-intern persona in a document session. The script is
# s10 with one more request in turn 3: set the persona before the question.
# A persona changes how a question is framed and nothing else, so every s10
# assert must still hold: the same verbatim record, the same unaided label,
# the same solid close at stage 0, the same citations, digests and snapshot.
# Those are run from the s10 script. The checks below are on the persona
# itself: saved to the profile, difficulty untouched, and written nowhere else.
# The harness copied profile.md into $STATE/snap right after the persona
# command, before any answer was given.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../../save-point/scripts"
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }
# field_of <profile> <key> -> the frontmatter value, spaces and quotes dropped.
field_of() {
  [ -f "$1" ] || return 0
  awk -v k="$2" 'NR == 1 && /^---/ { inf = 1; next } inf && /^---/ { exit } inf && index($0, k ":") == 1 { sub(/^[^:]*:/, ""); print; exit }' "$1" \
    | tr -d ' \t\r"'"'"
}

sh "$here/s10-doc-solid-close.sh" || fails=$((fails + $?))

want=$(sh "$scripts/derive-repo-id.sh" --doc "$DOC/brief.md" | tail -1)
p="$STATE/profile.md"
s1="$STATE/snap/profile-persona.md"
r="$STATE/repositories/$want/recall.md"
w="$STATE/repositories/$want/savepoint.md"

# --- the persona is a profile setting ---
v1=$(field_of "$s1" persona)
[ "$v1" = "new-intern" ] && ok "persona saved to the profile before the question (persona: new-intern)" || bad "persona not saved after the persona command: '${v1:-missing}'"
v2=$(field_of "$p" persona)
[ "$v2" = "new-intern" ] && ok "persona still new-intern at the end" || bad "final persona: '${v2:-missing}'"
d=$(field_of "$p" difficulty)
[ "$d" = "new-engineer" ] && ok "difficulty untouched (new-engineer): persona and difficulty are independent" || bad "difficulty changed with the persona: '${d:-missing}'"
extra=""
[ -f "$p" ] && extra=$(awk 'NR == 1 && /^---/ { inf = 1; next } inf && /^---/ { exit } inf && NF { sub(/^[ \t]+/, ""); sub(/:.*/, ""); sub(/[ \t]+$/, ""); print }' "$p" \
  | grep -vE '^(version|setup_status|goal|idk_policy|difficulty|persona|preferred_depth|feedback_timing|repetition_mode|recall_intervals|intensive_offered|daily_limit|minimum_gap|questions_per_interruption|default_snooze|interruption_style|cross_repo_recall|question_stats)$')
[ -f "$p" ] && [ -z "$extra" ] && ok "profile frontmatter holds only template fields" || bad "profile missing or invented field(s): $(printf '%s' "$extra" | tr '\n' ' ')"

# --- the persona is written nowhere else, and the records keep their shape ---
[ -f "$r" ] && ! strip "$r" | grep -qiE '^[[:space:]]*([-*][[:space:]]+)?[a-z_]*persona[a-z_]*:' && ok "no persona field in recall.md" || bad "a persona field was written to recall.md"
[ -f "$w" ] && ! strip "$w" | grep -qiE '^[[:space:]]*([-*][[:space:]]+)?[a-z_]*persona[a-z_]*:' && ok "no persona field in savepoint.md" || bad "a persona field was written to savepoint.md"
missing=""
for f in due_at created_at source_paths source_sha256 stage importance section last_assisted last_quality; do
  [ -f "$r" ] && strip "$r" | grep -qE "^[[:space:]]*([-*][[:space:]]+)?$f:" || missing="$missing $f"
done
[ -z "$missing" ] && ok "recall item carries the template fields" || bad "recall item lacks field(s):$missing"
# One question is answered, so one item holds a verdict. A second item may
# exist: after the bare "skip" of setup the agent may open a question of its
# own, which turn 3 then defers (see eval/README.md). Such an item must be
# untested. The persona must not add a graded question.
[ -f "$r" ] && [ "$(strip "$r" | grep -cE 'last_quality: (solid|shaky|failed|superseded)')" = "1" ] && ok "exactly one recall item holds a verdict" || bad "expected one item with a verdict: the persona must not add a graded question"
[ -f "$r" ] && ! strip "$r" | grep -q 'last_assisted: true' && ok "last_assisted not set: a persona's framing is not assistance" || bad "last_assisted: true on an unaided answer"
[ -f "$w" ] && [ "$(strip "$w" | grep -cE '^## q[0-9]+ — ')" = "1" ] && ok "exactly one savepoint entry" || bad "expected one savepoint entry"

exit $fails
