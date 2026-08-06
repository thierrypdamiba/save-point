#!/bin/sh
# Asserts for s09: cross-repo pending answer. Away from octo/api the due
# question gets a blind append headed pending-evaluation (unaided) — no
# verdict, no quality change, no reschedule; back inside the repository the
# pending entry is evaluated first, relabeled to the classification recorded
# in its heading, and that evaluation IS the close (quality signal, reschedule).
# The harness snapshotted the mid-run octo/api state into $STATE/snap between
# the blind append and the return.
# RISK NOTE: this scenario can legitimately FAIL when the model grades the
# answer away from octo/api, or closes the return superseded (no drift
# occurred) or unresolved (its own digest mismatching) — those are exactly
# the violations being measured; do not soften these asserts.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

sr="$STATE/snap/recall.md"
sw="$STATE/snap/savepoint.md"
fr="$STATE/repositories/540b016418280e51939c/recall.md"
fw="$STATE/repositories/540b016418280e51939c/savepoint.md"

# Template example entries live inside <!-- --> comments and carry literal
# "## q001" / "— pending-evaluation (unaided) @" headings plus example field
# lines; ignore them everywhere. The harness rewound the whole timeline one
# day (elapse-days.sh), leaving the item's due_at minutes in the past: a
# blind append must keep it in the past, and the evaluation close must move
# it into the future (ISO UTC strings compare lexicographically).
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }
# Prints the named item's due_at value from a recall.md.
due_of() { item "$1" "$2" | grep -E '^[[:space:]]*([-*][[:space:]]+)?due_at:' | head -1 | sed 's/.*due_at:[[:space:]]*//'; }
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# Prints the named item's section from a recall.md, comments stripped.
item() { strip "$1" | awk -v q="$2" 'f && /^## / { exit } f { print } $1 == "##" && index($2, q) == 1 { f = 1 }'; }

# Heading above each marker's entry (nearest real ## line above the marker).
hs=""; hf=""; hp=""
[ -f "$sw" ] && hs=$(strip "$sw" | awk '/^## / { h = $0 } index($0, "CORMORANT") { last = h } END { print last }')
[ -f "$fw" ] && hf=$(strip "$fw" | awk '/^## / { h = $0 } index($0, "CORMORANT") { last = h } END { print last }')
[ -f "$fw" ] && hp=$(strip "$fw" | awk '/^## / { h = $0 } index($0, "PELICAN") { print h; exit }')
qid=$(printf '%s\n' "$hs" | grep -oE 'q[0-9]+' | head -1)

# --- mid-run snapshot: right after the cross-repo blind append ---
[ -f "$sr" ] && [ -f "$sw" ] && ok "mid-run snapshot captured" || bad "snapshot files missing under \$STATE/snap"
case "$hs" in *"— pending-evaluation (unaided) @"*) ok "cross-repo answer appended under pending-evaluation (unaided)" ;; *) bad "CORMORANT entry heading not pending-evaluation (unaided): ${hs:-missing}" ;; esac
[ -f "$sw" ] && grep -q 'PELICAN' "$sw" && ok "first answer still verbatim in the save file" || bad "PELICAN answer lost from the save file"
[ -n "$qid" ] && [ -f "$sr" ] && item "$sr" "$qid" | grep -q 'pending_evaluation: true' && ok "pending_evaluation: true set on the item" || bad "pending_evaluation not set on the pending item"
[ -n "$qid" ] && [ -f "$sr" ] && item "$sr" "$qid" | grep -qE 'answer_sha256:[[:space:]]*[0-9a-f]{64}' && ok "answer digest recorded (64 hex)" || bad "no answer_sha256 digest on the pending item"
[ -n "$qid" ] && [ -f "$sr" ] && item "$sr" "$qid" | grep -q 'last_quality: solid' && ok "blind append left last_quality: solid untouched" || bad "blind append changed last_quality away from solid"
dsnap=""; [ -n "$qid" ] && [ -f "$sr" ] && dsnap=$(due_of "$sr" "$qid")
[ -n "$dsnap" ] && [ ! "$dsnap" \> "$now" ] && ok "blind append did not reschedule (due_at still in the past)" || bad "blind append rescheduled the item — due_at: ${dsnap:-missing}"

# --- final state: back inside octo/api, pending evaluated first ---
case "$hf" in *"— unaided @"*) ok "pending entry relabeled to its recorded classification (unaided)" ;; *) bad "CORMORANT entry not relabeled unaided: ${hf:-missing}" ;; esac
[ -f "$fw" ] && [ "$(grep -c 'CORMORANT' "$fw")" -eq 1 ] && ok "exactly one CORMORANT entry — relabeled in place, not duplicated" || bad "CORMORANT entry missing or duplicated"
[ -f "$fw" ] && ! strip "$fw" | grep -qE '^## q[0-9]+ — pending-evaluation' && ok "no pending-evaluation heading left after the return" || bad "a pending-evaluation heading survived the return"
case "$hp" in *"— unaided @"*) ok "PELICAN entry still labeled unaided" ;; *) bad "PELICAN entry heading missing or changed: ${hp:-missing}" ;; esac
[ -f "$fw" ] && ! grep -qE '^## q[0-9]+ — open @' "$fw" && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -n "$qid" ] && [ -f "$fr" ] && item "$fr" "$qid" | grep -qE 'last_quality: (solid|shaky|failed)' && ok "evaluation recorded a quality signal" || bad "no quality signal from the pending evaluation"
[ -f "$fr" ] && ! grep -q 'pending_evaluation: true' "$fr" && ok "pending_evaluation cleared" || bad "pending_evaluation still true after evaluation"
dfin=""; [ -n "$qid" ] && [ -f "$fr" ] && dfin=$(due_of "$fr" "$qid")
[ -n "$dfin" ] && [ "$dfin" \> "$now" ] && ok "item rescheduled at the evaluation close (due_at in the future)" || bad "item not rescheduled after evaluation — due_at: ${dfin:-missing}"

# --- isolation: answer text stays in octo/api's save file, repos untouched ---
[ -f "$sr" ] && ! grep -qE 'PELICAN|CORMORANT' "$sr" && ok "no answer text in snapshot recall.md" || bad "answer text leaked into snapshot recall.md"
[ -f "$fr" ] && ! grep -qE 'PELICAN|CORMORANT' "$fr" && ok "no answer text in final recall.md" || bad "answer text leaked into final recall.md"
if grep -rE 'PELICAN|CORMORANT' "$STATE" 2>/dev/null | grep -v '/snap/' | grep -v '/540b016418280e51939c/' | grep -q .; then
  bad "answer text leaked outside octo/api's state directory"
else
  ok "answer text confined to octo/api's state directory"
fi
[ -d "$REPO/.git" ] && [ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ] && ok "octo/api repository untouched" || bad "octo/api repository was modified"
[ -d "$REPO2/.git" ] && [ -z "$(git -C "$REPO2" status --porcelain 2>/dev/null)" ] && ok "octo/web repository untouched" || bad "octo/web repository was modified"

exit $fails
