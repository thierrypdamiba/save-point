#!/bin/sh
# Digests of the files an answer key rests on, for recall.md source_sha256
# in document workspaces, where there is no git history to show drift.
# Usage: hash-source.sh [--snapshot <dir>] <file> ...
# Prints one line per file: the SHA-256 of its raw bytes, two spaces, the
# path as given. With --snapshot, each file is also copied to <dir>/<sha256>
# unless that copy exists, so the text an answer was right for outlives
# later edits. <dir> belongs under ~/.save-point; the files themselves are
# only read. Keep in exact agreement with SKILL.md.
set -eu

usage() { echo "usage: hash-source.sh [--snapshot <dir>] <file> ..." >&2; exit 1; }
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }

snap=""
if [ "${1:-}" = "--snapshot" ]; then
  [ $# -ge 2 ] && [ -n "$2" ] || usage
  snap=$2; shift 2
fi
[ $# -ge 1 ] || usage

for f in "$@"; do
  [ -f "$f" ] || { echo "error: not a file: $f" >&2; exit 1; }
done

if [ -n "$snap" ]; then
  mkdir -p "$snap"
  chmod 700 "$snap"
fi

for f in "$@"; do
  sum=$(sha256 < "$f" | cut -d' ' -f1)
  if [ -n "$snap" ] && [ ! -f "$snap/$sum" ]; then
    tmp="$snap/.$sum.$$"
    (umask 077 && cat < "$f" > "$tmp")
    mv "$tmp" "$snap/$sum"
  fi
  printf '%s  %s\n' "$sum" "$f"
done
