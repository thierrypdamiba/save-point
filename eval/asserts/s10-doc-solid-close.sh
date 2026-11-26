#!/bin/sh
# Asserts for s10: a document workspace outside any git repository. Skip
# setup, one solid reasoned unaided answer about a claim and its source,
# session end. Checks the --doc identity, the verbatim record, the digests
# and snapshot behind drift detection, and that the document folder is
# byte-for-byte what the fixture shipped.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../../save-point/scripts"
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }
digest() { sha256 < "$1" | cut -d' ' -f1; }
# Template example entries live inside <!-- --> comments; ignore them.
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }

want=$(sh "$scripts/derive-repo-id.sh" --doc "$DOC/brief.md" | tail -1)
p="$STATE/profile.md"
r="$STATE/repositories/$want/recall.md"
w="$STATE/repositories/$want/savepoint.md"
snaps="$STATE/repositories/$want/snapshots"

[ -f "$p" ] && grep -q '^setup_status: skipped' "$p" && ok "profile written with setup_status: skipped" || bad "profile.md missing or not skipped"
[ -f "$r" ] && [ -f "$w" ] && ok "state written under the --doc identity ($want)" || bad "no state under the derived document ID $want: $(ls "$STATE/repositories" 2>/dev/null | tr '\n' ' ')"
[ "$(ls "$STATE/repositories" 2>/dev/null | wc -l | tr -d ' ')" = "1" ] && ok "exactly one workspace directory" || bad "expected one workspace directory under repositories/"
[ -f "$w" ] && grep -q '^canonical_remote: doc:/' "$w" && ok "canonical_remote records the doc: identity string" || bad "canonical_remote is not a doc: path"
[ -f "$w" ] && grep -q '^sources_root: ' "$w" && ok "sources_root recorded in savepoint.md frontmatter" || bad "sources_root missing from savepoint.md frontmatter"
[ -f "$w" ] && grep -q 'KESTREL' "$w" && ok "answer recorded verbatim in savepoint.md" || bad "verbatim answer not in savepoint.md"
[ -f "$w" ] && strip "$w" | grep -qE '^## q[0-9]+ — unaided @' && ok "entry labeled unaided" || bad "no unaided entry heading"
[ -f "$w" ] && ! strip "$w" | grep -qE '^## q[0-9]+ — open @' && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -f "$r" ] && strip "$r" | grep -q 'last_quality: solid' && ok "quality signal solid recorded" || bad "no solid quality signal"
[ -f "$r" ] && strip "$r" | grep -q 'stage: 0' && ! strip "$r" | grep -qE 'stage: [1-3]' && ok "new item starts at stage 0" || bad "item did not start at stage 0"
[ -f "$r" ] && ! grep -q 'KESTREL' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"

# Citations and drift bookkeeping.
[ -f "$r" ] && strip "$r" | grep -E 'source_paths:' | grep -qE ':L[0-9]+' && ok "source_paths cites a line range" || bad "source_paths has no line-range citation"
[ -f "$r" ] && strip "$r" | grep -E 'source_paths:' | grep -q '@sources/ridership-counts.md' && ok "source_paths cites the supporting source note" || bad "source_paths does not cite @sources/ridership-counts.md"
d_counts=$(digest "$DOC/sources/ridership-counts.md")
[ -f "$r" ] && strip "$r" | grep -E 'source_sha256:' | grep -q "$d_counts" && ok "source_sha256 holds the cited source note's digest" || bad "source_sha256 lacks the digest of ridership-counts.md"
[ -f "$snaps/$d_counts" ] && [ "$(digest "$snaps/$d_counts")" = "$d_counts" ] && ok "snapshot of the cited source kept, named by its digest" || bad "no faithful snapshot of ridership-counts.md under snapshots/"

# The user's folders are read-only to Save Point.
diff -r "$here/../fixture-doc" "$DOC" >/dev/null 2>&1 && ok "document and sources folders untouched" || bad "document or sources folder was modified"
[ ! -e "$DOC/.git" ] && ok "document workspace is still not a git repository" || bad "a git repository was created in the document folder"

exit $fails
