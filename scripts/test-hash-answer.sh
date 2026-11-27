#!/bin/sh
# Checks hash-answer.sh against fixed digests. The canonical form must not drift,
# because a stored answer_sha256 is compared against a fresh digest later.
# Run from anywhere: sh scripts/test-hash-answer.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
H=save-point/scripts/hash-answer.sh
pass=0
# check <name> <expected sha256> <input printf format>
check() {
  got=$(printf "$3" | sh "$H")
  [ "$got" = "$2" ] || { echo "FAIL $1: got $got want $2"; exit 1; }
  pass=$((pass + 1))
}
ABC=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
A_B=$(printf 'a\n\nb' | sha256sum | cut -d' ' -f1)
check "plain" "$ABC" 'abc'
check "trailing newlines removed" "$ABC" 'abc\n\n\n'
check "quote marker with space" "$ABC" '> abc\n'
check "quote marker without space" "$ABC" '>abc\n'
check "CRLF" "$ABC" '> abc\r\n'
check "blockquote with blank quoted line" "$A_B" '> a\n>\n> b\n\n'
check "CRLF blockquote" "$A_B" '> a\r\n>\r\n> b\r\n'
# Only one space after the marker is part of the marker.
check "second space kept" "$(printf ' abc' | sha256sum | cut -d' ' -f1)" '>  abc\n'
# A change of one word changes the digest.
[ "$(printf 'abd' | sh "$H")" != "$ABC" ] || { echo "FAIL digest ignores a change"; exit 1; }
pass=$((pass + 1))
# File argument and stdin agree.
d=$(mktemp -d)
printf '> abc\n' > "$d/ans.md"
[ "$(sh "$H" "$d/ans.md")" = "$ABC" ] || { echo "FAIL file argument"; exit 1; }
[ "$(sh "$H" - < "$d/ans.md")" = "$ABC" ] || { echo "FAIL dash argument"; exit 1; }
pass=$((pass + 2))
# A missing file is an error with no digest on stdout.
if out=$(sh "$H" "$d/none" 2>/dev/null); then echo "FAIL missing file exited 0"; exit 1; fi
[ -z "$out" ] || { echo "FAIL missing file printed stdout"; exit 1; }
pass=$((pass + 1))
echo "hash-answer: $pass checks passed"
