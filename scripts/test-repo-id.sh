#!/bin/sh
# Checks repository id derivation, remote normalization, document identity and source digests.
# Run from anywhere: sh scripts/test-repo-id.sh. CI calls this file.
set -e
cd "$(dirname "$0")/.."
test "$(printf '%s' 'github.com/octo/api' | shasum -a 256 | cut -c1-20)" = "540b016418280e51939c"
sh save-point/scripts/derive-repo-id.sh .

for url in 'https://GitHub.com/Octo/API.git' 'git@github.com:octo/api.git' 'ssh://git@github.com:2222/octo/api'; do
  d=$(mktemp -d)
  git -C "$d" init -q
  git -C "$d" remote add origin "$url"
  canonical=$(sh save-point/scripts/derive-repo-id.sh "$d" | head -1)
  id=$(sh save-point/scripts/derive-repo-id.sh "$d" | tail -1)
  test "$canonical" = "github.com/octo/api" || { echo "FAIL canonical for $url: $canonical"; exit 1; }
  test "$id" = "540b016418280e51939c" || { echo "FAIL id for $url: $id"; exit 1; }
done
d=$(mktemp -d)
git -C "$d" init -q
sh save-point/scripts/derive-repo-id.sh "$d" | head -1 | grep -q '^/' || { echo "FAIL no-remote case"; exit 1; }

d=$(mktemp -d)
mkdir -p "$d/ws/sources"
printf 'brief\n' > "$d/ws/brief.md"
printf 'note\n' > "$d/ws/sources/note.md"
real=$(cd "$d/ws" && pwd -P)
canonical=$(sh save-point/scripts/derive-repo-id.sh --doc "$d/ws/brief.md" | head -1)
id=$(sh save-point/scripts/derive-repo-id.sh --doc "$d/ws/brief.md" | tail -1)
test "$canonical" = "doc:$real/brief.md" || { echo "FAIL doc canonical: $canonical"; exit 1; }
test "$id" = "$(printf '%s' "doc:$real/brief.md" | shasum -a 256 | cut -c1-20)" || { echo "FAIL doc id: $id"; exit 1; }
script=$PWD/save-point/scripts/derive-repo-id.sh
test "$(cd "$d/ws" && sh "$script" --doc brief.md | tail -1)" = "$id" || { echo "FAIL relative path re-keys"; exit 1; }
printf 'edited\n' >> "$d/ws/brief.md"
test "$(sh "$script" --doc "$d/ws/brief.md" | tail -1)" = "$id" || { echo "FAIL edit re-keys"; exit 1; }
test "$(sh "$script" --doc "$d/ws/" | head -1)" = "doc:$real" || { echo "FAIL folder canonical"; exit 1; }
git -C "$d/ws" init -q
test "$(sh "$script" "$d/ws" | head -1)" = "$real" || { echo "FAIL repository path identity changed"; exit 1; }
test "$(sh "$script" --doc "$d/ws" | tail -1)" != "$(sh "$script" "$d/ws" | tail -1)" || { echo "FAIL doc and repository IDs collide"; exit 1; }
if sh "$script" --doc "$d/missing" 2>/dev/null; then echo "FAIL missing path accepted"; exit 1; fi
want=$(shasum -a 256 < "$d/ws/sources/note.md" | cut -d' ' -f1)
out=$(sh save-point/scripts/hash-source.sh --snapshot "$d/state/snapshots" "$d/ws/sources/note.md")
test "$out" = "$want  $d/ws/sources/note.md" || { echo "FAIL hash-source output: $out"; exit 1; }
cmp -s "$d/state/snapshots/$want" "$d/ws/sources/note.md" || { echo "FAIL snapshot copy"; exit 1; }
printf 'changed\n' >> "$d/ws/sources/note.md"
test "$(sh save-point/scripts/hash-source.sh "$d/ws/sources/note.md" | cut -d' ' -f1)" != "$want" || { echo "FAIL digest ignores an edit"; exit 1; }
test "$(printf 'note\n' | shasum -a 256 | cut -d' ' -f1)" = "$(shasum -a 256 < "$d/state/snapshots/$want" | cut -d' ' -f1)" || { echo "FAIL snapshot changed with the file"; exit 1; }
test "$(ls "$d/ws" | tr '\n' ' ')" = "brief.md sources " || { echo "FAIL wrote into the document folder"; exit 1; }
if sh save-point/scripts/hash-source.sh "$d/ws" 2>/dev/null; then echo "FAIL folder accepted as a file"; exit 1; fi

# Outside a git repository: one clear line that names --doc, exit 1, nothing on stdout.
e=$(mktemp -d)
if out=$(cd "$e" && sh "$script" 2>"$e.err"); then echo "FAIL non-repo accepted"; exit 1; fi
rc=0; (cd "$e" && sh "$script" >/dev/null 2>&1) || rc=$?
test "$rc" = 1 || { echo "FAIL non-repo exit $rc"; exit 1; }
test -z "$out" || { echo "FAIL non-repo stdout"; exit 1; }
test "$(wc -l < "$e.err" | tr -d ' ')" = 1 || { echo "FAIL non-repo stderr not one line"; exit 1; }
grep -q -- '--doc' "$e.err" || { echo "FAIL non-repo message lacks --doc"; exit 1; }
grep -q 'fatal' "$e.err" && { echo "FAIL raw git error shown"; exit 1; }
test -z "$(ls -A "$e")" || { echo "FAIL non-repo wrote files"; exit 1; }

# Extra arguments are refused: one usage line, exit 1, nothing on stdout.
x=$(mktemp -d)
for args in "$x $x" "--doc $x $x"; do
  rc=0; out=$(sh "$script" $args 2>"$x.err") || rc=$?
  test "$rc" = 1 || { echo "FAIL extra args '$args' exit $rc"; exit 1; }
  test -z "$out" || { echo "FAIL extra args '$args' stdout"; exit 1; }
  test "$(wc -l < "$x.err" | tr -d ' ')" = 1 || { echo "FAIL extra args '$args' stderr not one line"; exit 1; }
  grep -q '^usage: derive-repo-id.sh' "$x.err" || { echo "FAIL extra args '$args' message"; exit 1; }
done
