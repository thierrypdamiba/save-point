#!/bin/sh
# Asserts for s01: skip setup, one solid reasoned unaided answer, session end.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

p="$STATE/profile.md"
r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

# The templates ship example entries inside <!-- --> comments. The one in
# savepoint.md has a literal "## q001 — unaided @" heading, and the one in
# recall.md has "stage: 0". A grep of the whole file can match those when the
# model kept the comment, so every check reads the file with comments removed.
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }
# The heading of the entry that holds the scripted answer: the nearest real
# "## " line above the marker word. The label is checked on that entry, so an
# unaided heading somewhere else in the file cannot pass for it.
h=""
[ -n "$w" ] && h=$(strip "$w" | awk '/^## / { cur = $0 } index($0, "GOLDFINCH") { print cur; exit }')

[ -f "$p" ] && grep -q '^setup_status: skipped' "$p" && ok "profile written with setup_status: skipped" || bad "profile.md missing or not skipped"
case "$r" in */540b016418280e51939c/*) ok "repository ID derived correctly" ;; *) bad "repository ID wrong or missing: $r" ;; esac
[ -n "$w" ] && strip "$w" | grep -q 'GOLDFINCH' && ok "answer recorded verbatim in savepoint.md" || bad "verbatim answer not in savepoint.md"
case "$h" in *"— unaided @"*) ok "entry labeled unaided" ;; *) bad "the answer's entry is not labeled unaided: ${h:-missing}" ;; esac
[ -n "$w" ] && ! strip "$w" | grep -qE '^## q[0-9]+ — open @' && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -n "$r" ] && strip "$r" | grep -q 'last_quality: solid' && ok "quality signal solid recorded" || bad "no solid quality signal"
[ -n "$r" ] && strip "$r" | grep -q 'stage: 0' && ok "new item starts at stage 0" || bad "item did not start at stage 0"
[ -n "$r" ] && ! grep -q 'GOLDFINCH' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"
[ -f "$REPO/.git/config" ] && [ -z "$(git -C "$REPO" status --porcelain)" ] && ok "repository untouched" || bad "repository was modified"

exit $fails
