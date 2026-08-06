#!/bin/sh
# Asserts for s01: skip setup, one solid reasoned unaided answer, session end.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

p="$STATE/profile.md"
r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

[ -f "$p" ] && grep -q '^setup_status: skipped' "$p" && ok "profile written with setup_status: skipped" || bad "profile.md missing or not skipped"
case "$r" in */540b016418280e51939c/*) ok "repository ID derived correctly" ;; *) bad "repository ID wrong or missing: $r" ;; esac
[ -n "$w" ] && grep -q 'GOLDFINCH' "$w" && ok "answer recorded verbatim in savepoint.md" || bad "verbatim answer not in savepoint.md"
[ -n "$w" ] && grep -qE '^## q[0-9]+ — unaided @' "$w" && ok "entry labeled unaided" || bad "no unaided entry heading"
[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — open @' "$w" && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -n "$r" ] && grep -q 'last_quality: solid' "$r" && ok "quality signal solid recorded" || bad "no solid quality signal"
[ -n "$r" ] && grep -q 'stage: 0' "$r" && ok "new item starts at stage 0" || bad "item did not start at stage 0"
[ -n "$r" ] && ! grep -q 'GOLDFINCH' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"
[ -f "$REPO/.git/config" ] && [ -z "$(git -C "$REPO" status --porcelain)" ] && ok "repository untouched" || bad "repository was modified"

exit $fails
