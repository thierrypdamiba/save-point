#!/bin/sh
# Asserts for s04: fragment request, confirmation request, then skip with no
# answer text ever given. The recall item must survive so the question comes
# back, savepoint.md must hold no entry (nothing verbatim exists), and the
# transcripts while the question is open must never state the mechanism.
set -u
fails=0
ok() { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; fails=$((fails + 1)); }

r=$(ls "$STATE"/repositories/*/recall.md 2>/dev/null | head -1)
w=$(ls "$STATE"/repositories/*/savepoint.md 2>/dev/null | head -1)

# The templates ship a commented-out example entry (## q001, stage: 0,
# last_quality: untested ...) that would satisfy or trip these greps if the
# model kept it; strip HTML comments so only real records are seen. Erase
# single-line "<!-- ... -->" comments first, so one cannot open a block
# delete that swallows real records below it.
strip() { sed -e 's/<!--.*-->//g' -e '/<!--/,/-->/d' "$1"; }

case "$r" in */540b016418280e51939c/*) ok "repository ID derived correctly" ;; *) bad "repository ID wrong or missing: $r" ;; esac
[ -n "$r" ] && strip "$r" | grep -qE '^## q[0-9]+' && ok "recall item exists for the skipped question" || bad "no recall item — a skip must keep the question coming back"
[ -n "$r" ] && strip "$r" | grep -q 'stage: 0' && ! strip "$r" | grep -qE 'stage: [1-3]' && ok "item held at stage 0" || bad "item not held at stage 0"
[ -n "$r" ] && strip "$r" | grep -q 'last_quality: untested' && ok "last_quality recorded untested" || bad "last_quality not untested"
[ -n "$r" ] && ! strip "$r" | grep -qE 'last_quality: (solid|shaky|failed|superseded)' && ok "no verdict recorded for an unanswered question" || bad "a verdict was recorded without any answer"

# Skip-before-any-answer writes nothing verbatim: the file may not even exist.
# The two requests in this script ("the first word", "is the retry cap five
# attempts, yes or no?") are questions put to the agent. By the rule in
# SKILL.md, "Evaluate answers", a request for a fragment, a hint, or a
# confirmation is not an answer attempt, so neither may be recorded as an
# entry, under any label (open, skipped, deferred, unresolved).
{ [ -z "$w" ] || ! strip "$w" | grep -qE '^## q[0-9]+'; } && ok "no savepoint entry — nothing verbatim was ever given" || bad "savepoint entry written despite no answer text (a confirmation or fragment request is not an answer attempt)"
{ [ -z "$w" ] || ! strip "$w" | grep -qE '^## q[0-9]+ — open @'; } && ok "no dangling open heading" || bad "provisional open heading left in savepoint.md"

# Leak check on the replies while the question is open (04: fragment request,
# 05: confirmation request) and at the skip close (06 — the key stays
# internal even after a skip, since the item returns at recall). Reply 03 —
# the question itself — is deliberately NOT scanned: the sandbox source
# comments literally say "exponential backoff", so a compliant question or
# chapter title naming that code area could false-FAIL a good run. None of
# the user's words in turns 4-6 contain these terms, so a hit in 04-06 is
# the model volunteering answer-key facts — EXCEPT when replies 01-03
# already named the backoff code area (a compliant question or chapter title
# may, per the code comment): probes restate the question's own wording and
# the session-end save point echoes chapter titles, so the name check is
# waived then; the formula check never is. Structure names (dead, attempts,
# retry cap) are not banned — questions and refusals legitimately quote
# them; bare "yes"/"no" is not banned — too flaky. The "2 **" exponent form
# is not grepped (markdown bold makes "2 **"/"2**" false-positive-prone); a
# stated formula still trips "* 100", "2^", or the ms constants.
# "double-check" is excised before grepping so the idiom cannot trip
# "doubl"; input is lowercased, so patterns are lowercase.
open_replies() {
  cat "$TURNS/04.txt" "$TURNS/05.txt" "$TURNS/06.txt" |
    tr '[:upper:]' '[:lower:]' | sed 's/double[- ]*check[a-z]*//g'
}
if [ -f "$TURNS/04.txt" ] && [ -f "$TURNS/05.txt" ] && [ -f "$TURNS/06.txt" ]; then
  ok "transcripts 04-06 present"
  if cat "$TURNS/01.txt" "$TURNS/02.txt" "$TURNS/03.txt" 2>/dev/null | grep -qiE 'exponent|back-?off'; then
    ok "name check waived: question/chapter named the code area before the leak window"
  elif open_replies | grep -qE 'exponent|back-?off'; then
    bad "leak: backoff mechanism named while the question was open or skipped"
  else
    ok "no exponential/backoff leak in replies 04-06"
  fi
  if open_replies | grep -qE '\* ?100|times ?100|[0-9]00 ?(ms|millis)|doubl|2\^|powers? of (two|2)'; then
    bad "leak: delay constant, doubling, or exponent formula stated in replies 04-06"
  else
    ok "no delay-formula leak in replies 04-06"
  fi
else
  bad "transcripts 04-06 missing from \$TURNS"
fi

exit $fails
