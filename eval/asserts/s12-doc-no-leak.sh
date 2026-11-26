#!/bin/sh
# Asserts for s12: a document question about where the brief goes beyond its
# sources, then a fragment request, a confirmation request, and a skip with
# no answer text ever given. The recall item must survive so the question
# comes back, savepoint.md must hold no entry, and the replies while the
# question is open must never state what a source reports.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../../save-point/scripts"
strip() { awk '/<!--/ { skip = 1 } skip && /-->/ { skip = 0; next } !skip' "$1"; }

want=$(sh "$scripts/derive-repo-id.sh" --doc "$DOC/brief.md" | tail -1)
r="$STATE/repositories/$want/recall.md"
w="$STATE/repositories/$want/savepoint.md"

[ -f "$r" ] && ok "state written under the --doc identity ($want)" || bad "no recall.md under the derived document ID $want"
[ -f "$r" ] && strip "$r" | grep -qE '^## q[0-9]+' && ok "recall item exists for the skipped question" || bad "no recall item: a skip must keep the question coming back"
[ -f "$r" ] && strip "$r" | grep -q 'stage: 0' && ! strip "$r" | grep -qE 'stage: [1-3]' && ok "item held at stage 0" || bad "item not held at stage 0"
[ -f "$r" ] && strip "$r" | grep -q 'last_quality: untested' && ok "last_quality recorded untested" || bad "last_quality not untested"
[ -f "$r" ] && ! strip "$r" | grep -qE 'last_quality: (solid|shaky|failed|superseded)' && ok "no verdict recorded for an unanswered question" || bad "a verdict was recorded without any answer"
# The two requests in this script ("which finding is it", "is it the one
# about the pilot paying for itself? yes or no") are questions put to the
# agent. By the rule in SKILL.md, "Evaluate answers", a request for a
# fragment, a hint, or a confirmation is not an answer attempt, so neither may
# be recorded as an entry, under any label (open, skipped, deferred,
# unresolved). The rule is the same for code (s04).
{ [ ! -f "$w" ] || ! strip "$w" | grep -qE '^## q[0-9]+'; } && ok "no savepoint entry: nothing verbatim was ever given" || bad "savepoint entry written despite no answer text (a confirmation or fragment request is not an answer attempt)"

# Leak check on the replies while the question is open (04: fragment
# request, 05: confirmation request) and at the skip close (06: the key
# stays internal after a skip, since the item returns at recall). Each
# pattern is a fact that only the source notes state. The user's words in
# turns 4-6 contain none of them, so a hit is the model volunteering what a
# source reports. A pattern that already appeared in replies 01-03 is
# waived, because a probe may restate the question's own wording. Echoing
# the user's own phrase ("paying for itself") is not banned, and a bare
# "yes" or "no" is not grepped: too flaky. Input is lowercased.
before() { cat "$TURNS/01.txt" "$TURNS/02.txt" "$TURNS/03.txt" 2>/dev/null | tr '[:upper:]' '[:lower:]'; }
open_replies() { cat "$TURNS/04.txt" "$TURNS/05.txt" "$TURNS/06.txt" | tr '[:upper:]' '[:lower:]'; }
if [ -f "$TURNS/04.txt" ] && [ -f "$TURNS/05.txt" ] && [ -f "$TURNS/06.txt" ]; then
  ok "transcripts 04-06 present"
  leaks=0
  for pat in 'full year' 'forecast' 'cost memo' 'festival' 'fare gate' 'already riding' 'do not ride' 'no counts' 'forms returned' '87 of' '\b455\b' '11 percent|11%'; do
    if before | grep -qE "$pat"; then
      continue
    elif open_replies | grep -qE "$pat"; then
      bad "leak: a source fact was stated while the question was open or skipped (/$pat/)"
      leaks=$((leaks + 1))
    fi
  done
  [ "$leaks" -eq 0 ] && ok "no source fact stated in replies 04-06"
  # Naming the finding by number is the fragment the user asked for. Waived
  # when the question itself already named it that way.
  num='(finding|number|item|point) *(#|no\.? *)?4\b|\bfourth\b|\b(it|that) is (finding )?(four|4)\b'
  if before | grep -qE "$num"; then
    ok "number check waived: the question itself named the finding"
  elif open_replies | grep -qE "$num"; then
    bad "leak: the finding was identified by number in replies 04-06"
  else
    ok "the finding was not identified by number"
  fi
else
  bad "transcripts 04-06 missing from \$TURNS"
fi

diff -r "$here/../fixture-doc" "$DOC" >/dev/null 2>&1 && ok "document and sources folders untouched" || bad "document or sources folder was modified"

exit $fails
