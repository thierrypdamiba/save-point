#!/bin/sh
# Asserts for s11: document drift between sessions, with no git history to
# consult. Session 1 closes a solid unaided answer (DUNLIN) about the
# ridership claim and its source. The harness then revises the brief and the
# source note from 18 percent to 11 percent and rewinds the timeline one day.
# The stale re-answer (SANDPIPER) is right for the text as it was and wrong
# for the text as it is: the contract requires a superseded close, with the
# stage reset to 0, never failed. The only evidence of the old text is the
# recorded digest and the snapshot.
# RISK NOTE: this scenario can legitimately FAIL when the model skips the
# digest and snapshot check and grades the stale answer "failed". That is
# the contract violation being measured; do not soften these asserts.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../../save-point/scripts"
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }
digest() { sha256 < "$1" | cut -d' ' -f1; }
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }

want=$(sh "$scripts/derive-repo-id.sh" --doc "$DOC/brief.md" | tail -1)
r="$STATE/repositories/$want/recall.md"
w="$STATE/repositories/$want/savepoint.md"
snaps="$STATE/repositories/$want/snapshots"
rc=""; [ -f "$r" ] && rc=$(strip "$r")

# Harness sanity: the drift must be on disk or the scenario is moot.
grep -q 'rose 11 percent' "$DOC/brief.md" && grep -q 'Change: 11 percent' "$DOC/sources/ridership-counts.md" && ok "harness drift applied (brief and source now say 11 percent)" || bad "harness drift missing from the fixture copy"

[ -f "$r" ] && [ -f "$w" ] && ok "state written under the --doc identity ($want)" || bad "no state under the derived document ID $want"
[ "$(ls "$STATE/repositories" 2>/dev/null | wc -l | tr -d ' ')" = "1" ] && ok "the edit did not re-key the workspace" || bad "expected one workspace directory under repositories/"

[ -f "$w" ] && grep -q 'DUNLIN' "$w" && ok "first answer recorded verbatim" || bad "DUNLIN answer not in savepoint.md"
[ -f "$w" ] && grep -q 'SANDPIPER' "$w" && ok "stale re-answer recorded verbatim" || bad "SANDPIPER answer not in savepoint.md"

hd=""; hs=""
if [ -f "$w" ]; then
  hd=$(strip "$w" | awk '/^## q/ { h = $0 } index($0, "DUNLIN") { print h; exit }')
  hs=$(strip "$w" | awk '/^## q/ { h = $0 } index($0, "SANDPIPER") { print h; exit }')
fi
case "$hd" in *"— unaided @"*) ok "DUNLIN entry labeled unaided, unchanged" ;; *) bad "DUNLIN entry heading not unaided: ${hd:-missing}" ;; esac
case "$hs" in *"— superseded @"*) ok "SANDPIPER entry closed superseded" ;; *) bad "SANDPIPER entry heading not superseded: ${hs:-missing}" ;; esac
case "$hs" in "") bad "SANDPIPER entry heading missing" ;; *failed*) bad "SANDPIPER entry labeled failed: drift graded as forgetting" ;; *) ok "SANDPIPER entry not labeled failed" ;; esac

idd=$(printf '%s\n' "$hd" | grep -oE 'q[0-9]+' | head -1)
ids=$(printf '%s\n' "$hs" | grep -oE 'q[0-9]+' | head -1)
[ -n "$idd" ] && [ "$idd" = "$ids" ] && ok "recall attempt appended under the same question ID ($idd)" || bad "question IDs differ between attempts: '${idd:-none}' vs '${ids:-none}'"

[ -f "$w" ] && ! strip "$w" | grep -qE '^## q[0-9]+ — open @' && ok "no dangling open entries" || bad "provisional open entry never relabeled"

[ -n "$rc" ] && printf '%s\n' "$rc" | grep -q 'last_quality: superseded' && ok "quality signal superseded recorded" || bad "no superseded quality signal in recall.md"
[ -n "$rc" ] && ! printf '%s\n' "$rc" | grep -q 'last_quality: failed' && ok "not graded failed" || bad "last_quality: failed, the document changing treated as forgetting"
[ -n "$rc" ] && printf '%s\n' "$rc" | grep -q 'stage: 0' && ! printf '%s\n' "$rc" | grep -qE 'stage: [1-3]' && ok "item back at stage 0" || bad "stage not reset to 0"
# The harness rewound the whole timeline one day, so "rescheduled" means the
# superseded item's due_at is in the future again (ISO UTC strings compare
# lexicographically).
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
dsup=$(printf '%s\n' "$rc" | awk '/^## q/ { if (buf ~ /last_quality: superseded/) out = buf; buf = "" } { buf = buf "\n" $0 } END { if (buf ~ /last_quality: superseded/) out = buf; print out }' \
  | grep -E '^[[:space:]]*([-*][[:space:]]+)?due_at:' | head -1 | sed 's/.*due_at:[[:space:]]*//')
[ -n "$dsup" ] && [ "$dsup" \> "$now" ] && ok "item rescheduled at the superseded close (due_at in the future)" || bad "close did not reschedule, due_at: ${dsup:-missing}"
[ -f "$r" ] && ! grep -qE 'DUNLIN|SANDPIPER' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"

# Drift bookkeeping: the old text survives as a snapshot, and the item now
# points at the current text.
d_old=$(digest "$here/../fixture-doc/sources/ridership-counts.md")
d_new=$(digest "$DOC/sources/ridership-counts.md")
[ -f "$snaps/$d_old" ] && [ "$(digest "$snaps/$d_old")" = "$d_old" ] && ok "snapshot of the source as first cited is kept" || bad "no faithful snapshot of the original ridership-counts.md"
[ -n "$rc" ] && printf '%s\n' "$rc" | grep -E 'source_sha256:' | grep -q "$d_new" && ok "source_sha256 refreshed to the current source text" || bad "source_sha256 not refreshed to the current ridership-counts.md digest"

# The user's folders are read-only to Save Point: nothing changed beyond
# the harness edit, and nothing was added.
if [ -f "$STATE/snap/doc-manifest" ]; then
  (cd "$DOC" && find . -type f | LC_ALL=C sort | xargs cksum) | diff - "$STATE/snap/doc-manifest" >/dev/null 2>&1 \
    && ok "document and sources folders untouched by the model" || bad "document or sources folder modified beyond the harness drift"
else
  bad "harness manifest missing under \$STATE/snap"
fi

exit $fails
