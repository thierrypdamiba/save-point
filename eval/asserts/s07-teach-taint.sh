#!/bin/sh
# Asserts for s07: solid unaided close, then "teach me" after the close.
# Teaching is free — but it must taint the concept (last_assisted: true) and
# spawn a NEW stage-0 follow-up item, while the closed SANDPIPER attempt keeps
# its unaided label and solid signal untouched. No restatement is ever given,
# so no assisted entry may exist; every item is new this session, so none may
# sit above stage 0 (first closes never advance — SKILL.md "Schedule recall").
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

# Template example entries live inside <!-- --> comments; ignore them.
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }

[ -n "$w" ] && [ "$(grep -c 'SANDPIPER' "$w")" -eq 1 ] && ok "answer recorded verbatim, exactly one SANDPIPER entry" || bad "SANDPIPER missing, duplicated, or rewritten in savepoint.md"

sp_head=""
[ -n "$w" ] && sp_head=$(strip "$w" | awk '/^## /{h=$0} /SANDPIPER/{print h; exit}')
printf '%s\n' "$sp_head" | grep -qE '^## q[0-9]+ — unaided @' && ok "closed attempt kept its unaided label after teaching" || bad "SANDPIPER entry not under an unaided heading: $sp_head"

[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — open @' "$w" && ok "no dangling open entries" || bad "provisional open entry never relabeled"

[ -n "$w" ] && ! grep -qE '^## q[0-9]+ — assisted @' "$w" && ok "no assisted entry — no restatement was ever given to save" || bad "assisted entry fabricated without any user restatement"

ids=0
[ -n "$r" ] && ids=$(strip "$r" | grep -E '^## q[0-9]+' | awk '{print $2}' | sort -u | grep -c .)
[ "$ids" -ge 2 ] && ok "recall holds the answered item plus a distinct follow-up item" || bad "no distinct follow-up question created for the taught gap (ids: $ids)"

[ -n "$r" ] && strip "$r" | grep -q 'last_assisted: true' && ok "taught concept tainted with last_assisted: true" || bad "teaching did not set last_assisted: true on any item"

[ -n "$r" ] && strip "$r" | grep -q 'last_quality: solid' && ok "solid signal from the close preserved" || bad "solid quality signal missing or rewritten"

[ -n "$r" ] && strip "$r" | grep -q 'last_quality: untested' && ok "follow-up item carries untested (created without a close)" || bad "no untested item — follow-up missing or given a verdict"

[ -n "$r" ] && strip "$r" | grep -q 'stage: 0' && ok "a stage-0 item present — follow-up starts at stage 0" || bad "no stage-0 item"

[ -n "$r" ] && ! strip "$r" | grep -qE 'stage: ?[1-9]' && ok "no item above stage 0 — a first close never advances a new item" || bad "an item left stage 0 in a single first-close session"

[ -n "$r" ] && ! grep -q 'SANDPIPER' "$r" && ok "no answer text in recall.md" || bad "answer text leaked into recall.md"

exit $fails
