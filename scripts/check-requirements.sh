#!/bin/sh
# Check the "Requirements and platforms" section of docs/quickstart.md against the scripts.
# usage: check-requirements.sh [repo-root]
root=${1:-.}
[ $# -le 1 ] || { echo "usage: check-requirements.sh [repo-root]" >&2; exit 1; }
doc="$root/docs/quickstart.md"
[ -f "$doc" ] || { echo "FAIL no $doc" >&2; exit 1; }
sec=$(awk '/^## Requirements and platforms/{f=1;next} /^## /{f=0} f' "$doc")
[ -n "$sec" ] || { echo "FAIL quickstart has no Requirements and platforms section" >&2; exit 1; }
files="$root/install.sh $(ls "$root"/save-point/scripts/*.sh) $root/hooks/hooks.json"
# Commands that count as external tools if a script calls them.
vocab="awk sed tr cut grep sort head tail wc date sha256sum shasum git python3 iconv cat cp mv rm mkdir mktemp find dirname basename jq perl ln od xargs uniq stat readlink realpath openssl uname cmp diff touch chmod tee"
used() { # tool: is it called in a non-comment line
  # shellcheck disable=SC2086
  grep -vE '^[[:space:]]*#' $files | grep -qE "(^|[^A-Za-z0-9_./-])$1([[:space:];)|]|\$)"
}
fail=0
for t in $vocab; do
  if used "$t" && ! printf '%s\n' "$sec" | grep -q "\`$t\`"; then
    echo "FAIL a script calls $t but the section does not list it" >&2; fail=1
  fi
done
for t in $(printf '%s\n' "$sec" | grep -o '`[a-z0-9]*`' | tr -d '`' | sort -u); do
  case "$t" in sh) continue ;; esac
  case "$t" in node) grep -q '"node"' "$root/mcp-server/package.json" || { echo "FAIL node not in package.json engines" >&2; fail=1; }; continue ;; esac
  used "$t" || { echo "FAIL section lists $t but no script calls it" >&2; fail=1; }
done
for s in 'Linux' 'macOS' 'Windows' 'Node 20'; do
  printf '%s\n' "$sec" | grep -q "$s" || { echo "FAIL section lacks: $s" >&2; fail=1; }
done
[ "$fail" = 0 ] && echo "requirements section matches the scripts"
exit "$fail"
