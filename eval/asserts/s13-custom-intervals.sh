#!/bin/sh
# Asserts for s13: custom recall intervals. Session 1 sets the list to
# 3, 10, 45 days, then tries the list 10 5 2, which is not increasing and must
# be rejected with the old value kept. One question closes (KESTREL), so its
# new item sits at stage 0 and must be due 3 days out, not the default 1.
# The harness then moves the timeline back 3 days. Session 2 answers the due
# item again (MERLIN): whatever stage that close lands on, its due date must
# use the interval at that position in the custom list (stage 0: 3 days,
# stage 1: 10 days), never the default 1 or 7. Checks are made on the item the
# answers sit under, found by the marker words in savepoint.md.
# The harness copied profile.md into $STATE/snap after each intervals command,
# and recall.md after the 3-day rewind, so each step is checked on its own.
# NOTE on comment stripping: the recall.md template carries a commented example
# item ("- stage: 0", "- due_at: ..."), so item checks run on the file with
# <!-- --> blocks removed.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

p="$STATE/profile.md"
r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)
s1="$STATE/snap/profile-set.md"
s2="$STATE/snap/profile-rejected.md"
s3="$STATE/snap/recall-day3.md"

# intervals_of <profile> -> the frontmatter recall_intervals value as "3,10,45"
# (spaces, quotes and brackets dropped; empty if the field is missing).
intervals_of() {
  [ -f "$1" ] || return 0
  awk 'NR == 1 && /^---/ { inf = 1; next } inf && /^---/ { exit } inf && /^recall_intervals:/ { sub(/^recall_intervals:/, ""); print; exit }' "$1" \
    | tr -d ' \t\r"[]'"'"
}
# items <recall.md> -> one line per item: "<id> <stage> <due_at> <created_at>"
items() {
  awk '/^[[:space:]]*<!--/ { c = 1 } !c { print } /-->/ { c = 0 }' "$1" | awk '
    function flush() { if (id != "") print id, (stage == "" ? "-" : stage), (due == "" ? "-" : due), (created == "" ? "-" : created) }
    /^## q[0-9]+/ { flush(); id = $2; stage = ""; due = ""; created = "" }
    /^[[:space:]]*([-*][[:space:]]+)?stage:/ { stage = $NF }
    /^[[:space:]]*([-*][[:space:]]+)?due_at:/ { due = $NF }
    /^[[:space:]]*([-*][[:space:]]+)?created_at:/ { created = $NF }
    END { flush() }'
}
epoch() { date -u -d "$1" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || echo ""; }
# days_between <from-epoch> <to-epoch> -> whole days, rounded to the nearest
days_between() { echo $(( ($2 - $1 + 43200) / 86400 )); }
# want_days <stage> -> the custom list's interval at that position (empty if none)
want_days() { case "$1" in 0) echo 3 ;; 1) echo 10 ;; 2) echo 45 ;; *) echo "" ;; esac; }

case "$r" in */540b016418280e51939c/*) ok "repository ID derived correctly" ;; *) bad "repository ID wrong or missing: $r" ;; esac

# --- the intervals commands ---
v1=$(intervals_of "$s1")
[ "$v1" = "3,10,45" ] && ok "custom list saved to the profile (recall_intervals: 3, 10, 45)" || bad "custom list not saved after the intervals command: '${v1:-missing}'"
v2=$(intervals_of "$s2")
[ "$v2" = "3,10,45" ] && ok "list 10 5 2 rejected: the old value is still in place" || bad "profile changed by the rejected list: '${v2:-missing}'"
v3=$(intervals_of "$p")
[ "$v3" = "3,10,45" ] && ok "custom list still in the profile at the end" || bad "final recall_intervals: '${v3:-missing}'"
[ -f "$p" ] && ! grep -qE '10, *5, *2|5, *10|2, *5, *10' "$p" && ok "rejected list was not stored or repaired by sorting" || bad "profile holds the rejected list or a sorted repair of it"
[ -f "$p" ] && grep -q '^repetition_mode: adaptive' "$p" && ok "repetition mode untouched (adaptive)" || bad "repetition_mode changed or profile missing"

# The item under test is the one the answers sit under: the question ID on
# the heading above KESTREL. The model may hold a second item, for a question
# it had picked before the scripted topic and then deferred. Such an item is
# checked only when it has been rescheduled, since when it was first deferred
# relative to the intervals command is not scripted.
qid=""
[ -n "$w" ] && qid=$(awk '/^## q[0-9]+/ { h = $2 } index($0, "KESTREL") { print h; exit }' "$w")
qid2=""
[ -n "$w" ] && qid2=$(awk '/^## q[0-9]+/ { h = $2 } index($0, "MERLIN") { print h; exit }' "$w")

# --- session 1: the new item is due on the custom stage-0 interval ---
[ -n "$qid" ] && ok "first answer recorded verbatim (under $qid)" || bad "KESTREL answer not in savepoint.md"
line=""
[ -f "$s3" ] && [ -n "$qid" ] && line=$(items "$s3" | awk -v id="$qid" '$1 == id { print; exit }')
if [ -n "$line" ]; then
  set -- $line
  de=$(epoch "$3"); ce=$(epoch "$4"); d=""
  [ -n "$de" ] && [ -n "$ce" ] && d=$(days_between "$ce" "$de")
  [ "$2" = "0" ] && ok "new item starts at stage 0" || bad "$qid after session 1 is at stage $2, want 0"
  [ "$d" = "3" ] && ok "new item is due 3 days after creation, not the default 1" || bad "$qid after session 1 is due ${d:-?} day(s) after creation (due_at $3, created_at $4); the custom list says 3"
else
  bad "no item for the answered question in the session-1 snapshot"
  bad "session-1 due date cannot be checked"
fi

# --- session 2: the reschedule uses the custom list at the resulting stage ---
[ -n "$qid2" ] && [ "$qid2" = "$qid" ] && ok "recall answer recorded verbatim under the same question ID" || bad "MERLIN answer missing or under another ID: '${qid2:-none}' vs '${qid:-none}'"
now=$(date +%s)
line=""
[ -n "$r" ] && [ -n "$qid" ] && line=$(items "$r" | awk -v id="$qid" '$1 == id { print; exit }')
if [ -n "$line" ]; then
  set -- $line
  de=$(epoch "$3"); want=$(want_days "$2"); d=""
  [ -n "$de" ] && d=$(days_between "$now" "$de")
  [ -n "$want" ] && [ "$d" = "$want" ] && ok "recall close rescheduled on the custom list: stage $2 is due in $d days" || bad "$qid after the recall close: stage $2 is due in ${d:-?} day(s) (due_at $3); the custom list says ${want:-no such stage}"
  [ "$d" != "1" ] && [ "$d" != "7" ] && ok "due date is not on the default 1 or 7 days" || bad "$qid was rescheduled on the default list ($d days)"
else
  bad "no item for the answered question in recall.md"
  bad "recall due date cannot be checked"
fi
# Any other item that has been rescheduled since the rewind (due_at in the
# future) must sit on the custom list too.
others=0; others_bad=0
if [ -n "$r" ]; then
  items "$r" > "$STATE/snap/items-final.txt"
  while read -r id stage due created; do
    [ "$id" = "$qid" ] && continue
    de=$(epoch "$due"); [ -n "$de" ] && [ "$de" -gt "$now" ] || continue
    others=$((others + 1)); d=$(days_between "$now" "$de")
    [ "$d" = "$(want_days "$stage")" ] || { others_bad=$((others_bad + 1)); echo "  note: $id at stage $stage is due in $d day(s)"; }
  done < "$STATE/snap/items-final.txt"
fi
[ "$others_bad" -eq 0 ] && ok "every other rescheduled item is on the custom list ($others checked)" || bad "$others_bad other item(s) rescheduled off the custom list"

# --- records stay clean ---
[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — open @' "$w" && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -n "$r" ] && ! grep -qE 'KESTREL|MERLIN' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"
[ -f "$REPO/.git/config" ] && [ -z "$(git -C "$REPO" status --porcelain)" ] && ok "repository untouched" || bad "repository was modified"

exit $fails
