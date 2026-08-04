#!/bin/sh
# Deterministic recall scheduling. Usage:
#   reschedule.sh <stage 0-3> <quality untested|solid|shaky|failed|superseded> <assisted true|false> <importance 1-5>
# Prints two lines: the new stage, then the new due_at (UTC ISO-8601, now + the stage's interval).
# Rules (first match wins, then clamp) — keep in exact agreement with SKILL.md "Schedule recall".
set -eu

usage() { echo "usage: reschedule.sh <stage 0-3> <untested|solid|shaky|failed|superseded> <true|false> <importance 1-5>" >&2; exit 1; }
[ $# -eq 4 ] || usage
stage=$1; quality=$2; assisted=$3; importance=$4
case "$stage" in 0|1|2|3) ;; *) usage ;; esac
case "$quality" in untested|solid|shaky|failed|superseded) ;; *) usage ;; esac
case "$assisted" in true|false) ;; *) usage ;; esac
case "$importance" in 1|2|3|4|5) ;; *) usage ;; esac

case "$quality" in
  superseded) stage=0 ;;   # the code changed, not the memory: relearn from stage 0
  failed) stage=$((stage > 0 ? stage - 1 : 0)) ;;
  *) if [ "$assisted" = "true" ]; then
       : # keep stage
     elif [ "$quality" = "solid" ]; then
       stage=$((stage < 3 ? stage + 1 : 3))
     fi ;;   # shaky and untested keep the stage
esac
[ "$importance" -ge 4 ] && [ "$stage" -gt 2 ] && stage=2

case "$stage" in
  0) days=1 ;;
  1) days=7 ;;
  2) days=30 ;;
  3) days=90 ;;
esac

due=$(( $(date +%s) + days * 86400 ))
due_str=$(date -u -d "@$due" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$due" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
[ -n "$due_str" ] || { echo "cannot format date" >&2; exit 1; }
printf '%s\n%s\n' "$stage" "$due_str"
