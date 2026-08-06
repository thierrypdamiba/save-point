#!/bin/sh
# Asserts for s05: code drift between sessions. Session 1 closes a solid
# unaided answer (HERON). The harness then tightens the retry cap 5 -> 3,
# commits it, and forces the item due. The stale re-answer (PLOVER) is right
# for the code as it was and wrong for the code as it is: the contract
# requires a superseded close — honest label, stage reset to 0 — never failed.
# RISK NOTE: this scenario can legitimately FAIL when the model skips the
# git-history check and grades the stale answer "failed" — that is exactly
# the contract violation being measured; do not soften these asserts.
# NOTE on $rc: the recall.md template comment carries "stage: 0" and example
# field lines. Positive field checks and the reschedule check therefore run
# on $rc, the file with <!-- --> blocks stripped; negative wide-net greps
# stay full-file. The harness rewound the whole timeline one day
# (elapse-days.sh), so "rescheduled" means the item's due_at is in the
# future again.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)
rc=""
[ -n "$r" ] && rc=$(awk '/^[[:space:]]*<!--/ { c = 1 } !c { print } /-->/ { c = 0 }' "$r")

# Harness sanity: the drift must actually be on disk or the scenario is moot.
grep -q 'job.attempts >= 3' "$REPO/src/queue.js" && ok "harness drift applied (cap is 3 in current source)" || bad "harness drift missing — fixture still caps at 5"

case "$r" in */540b016418280e51939c/*) ok "repository ID derived correctly" ;; *) bad "repository ID wrong or missing: $r" ;; esac

[ -n "$w" ] && grep -q 'HERON' "$w" && ok "first answer recorded verbatim" || bad "HERON answer not in savepoint.md"
[ -n "$w" ] && grep -q 'PLOVER' "$w" && ok "stale re-answer recorded verbatim" || bad "PLOVER answer not in savepoint.md"

# Heading each marker's entry sits under (nearest ## qNNN line above it).
hh=""; hp=""
if [ -n "$w" ]; then
  hh=$(awk '/^## q/ { h = $0 } index($0, "HERON") { print h; exit }' "$w")
  hp=$(awk '/^## q/ { h = $0 } index($0, "PLOVER") { print h; exit }' "$w")
fi
case "$hh" in *"— unaided @"*) ok "HERON entry labeled unaided, unchanged" ;; *) bad "HERON entry heading not unaided: ${hh:-missing}" ;; esac
case "$hp" in *"— superseded @"*) ok "PLOVER entry closed superseded" ;; *) bad "PLOVER entry heading not superseded: ${hp:-missing}" ;; esac
case "$hp" in "") bad "PLOVER entry heading missing" ;; *failed*) bad "PLOVER entry labeled failed — drift graded as forgetting" ;; *) ok "PLOVER entry not labeled failed" ;; esac

idh=$(printf '%s\n' "$hh" | grep -oE 'q[0-9]+' | head -1)
idp=$(printf '%s\n' "$hp" | grep -oE 'q[0-9]+' | head -1)
[ -n "$idh" ] && [ "$idh" = "$idp" ] && ok "recall attempt appended under the same question ID ($idh)" || bad "question IDs differ between attempts: '${idh:-none}' vs '${idp:-none}'"

lh=$(grep -n 'HERON' "$w" 2>/dev/null | head -1 | cut -d: -f1)
lp=$(grep -n 'PLOVER' "$w" 2>/dev/null | head -1 | cut -d: -f1)
[ -n "$lh" ] && [ -n "$lp" ] && [ "$lh" -lt "$lp" ] && ok "PLOVER entry appended after HERON entry" || bad "entries missing or out of order"

[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — open @' "$w" && ok "no dangling open entries" || bad "provisional open entry never relabeled"

[ -n "$rc" ] && printf '%s\n' "$rc" | grep -q 'last_quality: superseded' && ok "quality signal superseded recorded" || bad "no superseded quality signal in recall.md"
[ -n "$r" ] && ! grep -q 'last_quality: failed' "$r" && ok "not graded failed" || bad "last_quality: failed — the world changing treated as forgetting"
[ -n "$rc" ] && printf '%s\n' "$rc" | grep -q 'stage: 0' && ok "item back at stage 0" || bad "no stage 0 item in recall.md"
[ -n "$r" ] && ! grep -qE 'stage: [1-3]' "$r" && ok "no item left above stage 0" || bad "stage not reset to 0"
# The superseded item's due_at must be in the future again (ISO UTC strings
# compare lexicographically). The forced-due instant is in the past by now.
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
dsup=$(printf '%s\n' "$rc" | awk '/^## q/ { if (buf ~ /last_quality: superseded/) out = buf; buf = "" } { buf = buf "\n" $0 } END { if (buf ~ /last_quality: superseded/) out = buf; print out }' \
  | grep -E '^[[:space:]]*([-*][[:space:]]+)?due_at:' | head -1 | sed 's/.*due_at:[[:space:]]*//')
[ -n "$dsup" ] && [ "$dsup" \> "$now" ] && ok "item rescheduled at the superseded close (due_at in the future)" || bad "close did not reschedule — due_at: ${dsup:-missing}"
[ -n "$r" ] && ! grep -qE 'HERON|PLOVER' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"

[ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ] && [ "$(git -C "$REPO" rev-list --count HEAD 2>/dev/null)" = "2" ] && ok "repository untouched by the model" || bad "repository modified beyond the harness drift"

exit $fails
