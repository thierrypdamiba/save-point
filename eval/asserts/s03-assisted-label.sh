#!/bin/sh
# Asserts for s03: "I don't know" -> hint -> good answer. The label must say assisted.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/walkthrough.md 2>/dev/null | head -1)

[ -n "$w" ] && grep -q 'KINGFISHER' "$w" && ok "answer recorded verbatim" || bad "verbatim answer missing"
[ -n "$w" ] && grep -qE '^## q[0-9]+ — assisted @' "$w" && ok "hinted answer labeled assisted" || bad "assisted work not labeled assisted"
[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — unaided @.*KINGFISHER' "$w" && ok "not mislabeled unaided" || bad "assisted answer presented as unaided"
[ -n "$r" ] && grep -q 'last_assisted: true' "$r" && ok "last_assisted flag set" || bad "last_assisted not set"
[ -n "$r" ] && grep -qE 'last_quality: (solid|shaky)' "$r" && ok "quality recorded honestly alongside the assist" || bad "no quality signal recorded"

exit $fails
