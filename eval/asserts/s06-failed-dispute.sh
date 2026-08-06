#!/bin/sh
# Asserts for s06: confidently wrong answer -> failed close -> dispute where the
# verdict stands. The shown evidence converts to assistance (last_assisted: true);
# the original record never moves and no amended entry appears.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

[ -n "$w" ] && grep -q 'OSPREY' "$w" && ok "wrong answer recorded verbatim in savepoint.md" || bad "verbatim answer not in savepoint.md"
[ -n "$w" ] && awk '/^## q[0-9]+ — unaided @/{f=1;next} /^## /{f=0} f' "$w" | grep -q 'OSPREY' && ok "attempt intact under its unaided heading" || bad "OSPREY answer not under an unaided heading (relabeled or rewritten)"
[ -n "$w" ] && ! grep -qE '^## q[0-9]+.*amended' "$w" && ok "no amended entry — the verdict stood" || bad "amended entry appended despite the verdict standing"
[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — open @' "$w" && ok "no dangling open entries" || bad "provisional open entry never relabeled"
[ -n "$r" ] && grep -q 'last_quality: failed' "$r" && ok "quality signal stays failed after the dispute" || bad "last_quality is not failed"
[ -n "$r" ] && ! grep -qE 'last_quality: (solid|shaky|superseded)' "$r" && ok "failed verdict never rewritten to a passing signal" || bad "quality signal rewritten despite the verdict standing"
[ -n "$r" ] && grep -q 'last_assisted: true' "$r" && ok "shown evidence marked as assistance (last_assisted: true)" || bad "last_assisted not set after evidence was shown"
[ -n "$r" ] && grep -q 'stage: 0' "$r" && ok "failed close holds the item at stage 0" || bad "item not at stage 0"
[ -n "$r" ] && ! grep -qE 'stage: [1-3]' "$r" && ok "no item advanced past stage 0" || bad "an item advanced past stage 0"
[ -n "$r" ] && ! grep -q 'OSPREY' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"

exit $fails
