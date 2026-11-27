#!/bin/sh
# Checks hash-source.sh: fixed digests, the snapshot copy, its permissions, and
# the error paths. A stored source_sha256 is compared against a fresh digest
# later, and a snapshot must hold the exact bytes the answer was right for.
# Run from anywhere: sh scripts/test-hash-source.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
H=$(pwd)/save-point/scripts/hash-source.sh
pass=0
fail() { echo "FAIL $1"; exit 1; }
ok() { pass=$((pass + 1)); }

d=$(mktemp -d)
cd "$d"
printf 'hello\n' > a
printf 'hello\n' > b
printf 'x\r\ny' > c
HELLO=5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03
CRLF=$(printf 'x\r\ny' | sha256sum | cut -d' ' -f1)

# Digest of raw bytes, one line per file, in the order given, path as given.
out=$(sh "$H" a b c)
[ "$out" = "$HELLO  a
$HELLO  b
$CRLF  c" ] || fail "digest lines: $out"
ok
# Raw bytes: the CRLF file is not normalized (unlike an answer digest).
[ "$CRLF" != "$(printf 'x\ny' | sha256sum | cut -d' ' -f1)" ] || fail "test input does not distinguish CRLF"
ok

# Snapshot: one copy per distinct digest, named by digest, exact bytes, private.
out=$(sh "$H" --snapshot snap a b c)
[ "$(ls -A snap | wc -l | tr -d ' ')" = "2" ] || fail "snapshot count"
ok
cmp -s a "snap/$HELLO" || fail "snapshot bytes a"
cmp -s c "snap/$CRLF" || fail "snapshot bytes c"
ok
[ "$(stat -c %a snap 2>/dev/null || stat -f %Lp snap)" = "700" ] || fail "snapshot dir mode"
[ "$(stat -c %a "snap/$HELLO" 2>/dev/null || stat -f %Lp "snap/$HELLO")" = "600" ] || fail "snapshot file mode"
ok
[ "$out" = "$(sh "$H" a b c)" ] || fail "snapshot run prints the same lines"
ok

# A later edit does not touch the stored copy, and the edit gets its own copy.
printf 'hello world\n' > a
sh "$H" --snapshot snap a >/dev/null
[ "$(cat "snap/$HELLO")" = "hello" ] || fail "old snapshot changed"
[ "$(ls -A snap | wc -l | tr -d ' ')" = "3" ] || fail "edited copy not stored"
ok
# No temp file is left behind.
for f in snap/.[!.]*; do [ ! -e "$f" ] || fail "temp file left in snapshot dir: $f"; done
ok

# Errors: exit 1, no digest on stdout, no snapshot directory for a bad file list.
if o=$(sh "$H" a nope 2>/dev/null); then fail "missing file exited 0"; fi
[ -z "$o" ] || fail "missing file printed stdout"
if o=$(sh "$H" --snapshot never a nope 2>/dev/null); then fail "missing file with snapshot exited 0"; fi
[ ! -e never ] || fail "snapshot dir created before files were checked"
mkdir dir
if sh "$H" dir >/dev/null 2>&1; then fail "directory exited 0"; fi
ok
for args in "" "--snapshot" "--snapshot snap"; do
  # shellcheck disable=SC2086
  if o=$(sh "$H" $args 2>&1); then fail "usage case '$args' exited 0"; fi
  case "$o" in usage:*) ;; *) fail "usage case '$args' message: $o" ;; esac
done
ok
echo "hash-source: $pass check groups passed"
