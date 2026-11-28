#!/bin/sh
# Canonical digest of a recorded answer, for recall.md answer_sha256.
# Usage: hash-answer.sh [file]   (reads stdin if no file)
# Canonical form: CRLF normalized to LF, leading ">" blockquote markers
# (with or without one following space) stripped per line, and all trailing
# newlines removed. Keep in exact agreement with SKILL.md.
set -eu

[ $# -le 1 ] || { echo "usage: hash-answer.sh [file]" >&2; exit 1; }

sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }
canon() { sed -e 's/\r$//' -e 's/^> \{0,1\}//' -e 's/^>$//'; }

if [ $# -ge 1 ] && [ "$1" != "-" ]; then
  [ -f "$1" ] || { echo "hash-answer.sh: not a file: $1" >&2; exit 1; }
  [ -r "$1" ] || { echo "hash-answer.sh: cannot read: $1" >&2; exit 1; }
  text=$(canon < "$1")
else
  text=$(canon)
fi
printf '%s' "$text" | sha256 | cut -d' ' -f1
