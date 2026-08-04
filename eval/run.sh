#!/bin/sh
# Behavioral eval harness: replays scripted user sessions against the live
# skill via `claude -p`, then mechanically asserts on the state files the
# model produced. This is what turns the feature contract from prose into
# measured per-model compliance.
#
# Usage: ./run.sh [scenario ...]        (default: every scenario)
#        MODEL=<model> ./run.sh         (optional model override)
#
# Cost note: each scenario is a real multi-turn model session (~4-6 turns).
set -eu

command -v claude >/dev/null 2>&1 || { echo "error: claude CLI not found on PATH" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
skill="$here/../save-point/SKILL.md"
model_flag=""; model_name="default"
[ -n "${MODEL:-}" ] && { model_flag="--model $MODEL"; model_name=$MODEL; }

run_scenario() {
  name=$1
  turns_file="$here/scenarios/$name.txt"
  assert_file="$here/asserts/$name.sh"
  [ -f "$turns_file" ] && [ -f "$assert_file" ] || { echo "missing scenario or asserts: $name" >&2; return 1; }

  work=$(mktemp -d)
  STATE="$work/state"; REPO="$work/repo"
  mkdir -p "$STATE" "$REPO/src"
  cp "$here"/fixture-src/*.js "$REPO/src/"
  git -C "$REPO" init -q
  git -C "$REPO" add -A && git -C "$REPO" commit -qm init
  git -C "$REPO" remote add origin https://github.com/octo/api.git

  preamble="You are an AI coding agent with the Agent Skill at $skill activated. Read that file now and follow it EXACTLY — it is your complete behavior contract. Its templates are in $(dirname "$skill")/assets/. Test-harness substitutions: wherever the skill says ~/.save-point, use $STATE instead; the current working repository is $REPO. Perform ALL file reads and writes for real, and derive the repository ID for real. I am the user; respond to each message exactly as the skill dictates. My first message is:"

  # Turns are separated by lines containing exactly "===" (CRLF-tolerant).
  turnsdir="$work/turns"; mkdir -p "$turnsdir"
  awk -v dir="$turnsdir" 'BEGIN { n = 1 } { sub(/\r$/, "") } /^===$/ { n++; next } { print >> (dir "/" sprintf("%02d", n)) }' "$turns_file"

  sid=""; turn_no=0
  for tf in "$turnsdir"/*; do
    turn_no=$((turn_no + 1))
    prompt=$(cat "$tf")
    [ "$turn_no" -eq 1 ] && prompt="$preamble

$prompt"
    errlog="$work/turn-$turn_no.stderr"
    if [ -z "$sid" ]; then
      out=$(cd "$work" && claude -p "$prompt" $model_flag --output-format json \
        --allowedTools "Read,Write,Edit,Bash,Glob,Grep" 2>"$errlog") || {
        echo "  claude failed on turn $turn_no:" >&2; cat "$errlog" >&2; rm -rf "$work"; return 1; }
      sid=$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["session_id"])') || sid=""
      [ -n "$sid" ] || { echo "  could not extract session id" >&2; rm -rf "$work"; return 1; }
    else
      out=$(cd "$work" && claude -p --resume "$sid" "$prompt" $model_flag --output-format json \
        --allowedTools "Read,Write,Edit,Bash,Glob,Grep" 2>"$errlog") || {
        echo "  claude failed on turn $turn_no:" >&2; cat "$errlog" >&2; rm -rf "$work"; return 1; }
    fi
    printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("  turn:", d["result"][:100].replace(chr(10)," "))'
  done

  ok=0
  STATE="$STATE" REPO="$REPO" sh "$assert_file" || ok=1
  rm -rf "$work"
  return $ok
}

total=0; passed=0
scenarios=${*:-$(ls "$here/scenarios" | sed 's/\.txt$//')}
for s in $scenarios; do
  total=$((total + 1))
  echo "── $s (model: $model_name)"
  if run_scenario "$s"; then
    passed=$((passed + 1)); echo "── $s: PASS"
  else
    echo "── $s: FAIL"
  fi
done
echo
echo "model=$model_name  passed=$passed/$total"
[ "$passed" -eq "$total" ]
