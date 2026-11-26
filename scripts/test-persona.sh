#!/bin/sh
# Checks check-persona.sh.
# Run from anywhere: sh scripts/test-persona.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
p=save-point/scripts/check-persona.sh
for name in default new-intern lead-researcher new-teammate senior-reviewer; do
  test "$(sh $p $name)" = "$name" || { echo "FAIL built-in persona: $name"; exit 1; }
done
test "$(sh $p 'New Intern')" = "new-intern" || { echo "FAIL name with a space"; exit 1; }
test "$(sh $p lead researcher)" = "lead-researcher" || { echo "FAIL name as two words"; exit 1; }
test "$(sh $p custom a skeptical CFO who dislikes jargon)" = '"custom: a skeptical CFO who dislikes jargon"' || { echo "FAIL custom persona"; exit 1; }
test "$(sh $p 'custom   spaced    out ')" = '"custom: spaced out"' || { echo "FAIL custom persona spacing"; exit 1; }
long=$(printf 'x%.0s' $(seq 200))
test "$(sh $p "custom $long")" = "\"custom: $long\"" || { echo "FAIL 200 characters refused"; exit 1; }
nl=$(printf 'two\nlines')
for bad in '' 'boss' 'customer' 'custom' 'custom   ' 'custom a "quoted" role' 'custom back\slash' "custom $nl" "custom x$long"; do
  if out=$(sh $p "$bad" 2>/dev/null); then echo "FAIL illegal persona accepted: '$bad'"; exit 1; fi
  test -z "$out" || { echo "FAIL illegal persona printed a value: '$bad'"; exit 1; }
  sh $p "$bad" 2>&1 | grep -q '^invalid persona: ' || { echo "FAIL no reason given for: '$bad'"; exit 1; }
done
grep -q '^persona: default$' save-point/assets/profile.md || { echo "FAIL profile template default"; exit 1; }
