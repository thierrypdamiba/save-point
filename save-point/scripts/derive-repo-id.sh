#!/bin/sh
# Derive the Save Point repository ID for the git repository at $1 (default: cwd).
# Prints two lines: the canonical identity string, then the 20-hex-char ID.
# Every client must produce identical output for the same repository.
#
# With --doc <file-or-folder>, derive the ID of a document workspace instead.
# No git is needed. The canonical string is "doc:" plus the absolute path,
# verbatim, with directory symlinks resolved. A symlink that is the file
# itself is not followed. Keep in exact agreement with SKILL.md.
set -eu

doc=""
if [ "${1:-}" = "--doc" ]; then
  [ $# -eq 2 ] && [ -n "$2" ] || { echo "usage: derive-repo-id.sh --doc <file-or-folder>" >&2; exit 1; }
  if [ -d "$2" ]; then
    doc=$(cd "$2" >/dev/null && pwd -P)
  elif [ -f "$2" ]; then
    doc=$(cd "$(dirname "$2")" >/dev/null && pwd -P)
    doc="${doc%/}/$(basename "$2")"
  else
    echo "error: no such file or folder: $2" >&2; exit 1
  fi
  url=""
else
  root=$(cd "${1:-.}" && git rev-parse --show-toplevel)
  root=$(cd "$root" && pwd -P)

  url=$(git -C "$root" remote get-url origin 2>/dev/null) || {
    first=$(git -C "$root" remote | LC_ALL=C sort | head -n 1)
    if [ -n "$first" ]; then
      url=$(git -C "$root" remote get-url "$first")
    else
      url=""
    fi
  }
fi

if [ -n "$doc" ]; then
  canonical="doc:$doc"   # document workspace: prefixed so it never equals a repository path
elif [ -z "$url" ]; then
  canonical="$root"   # no remotes: absolute resolved path, verbatim
else
  canonical=$(printf '%s' "$url" | awk '{
    u = $0
    if (u ~ /^[A-Za-z][A-Za-z0-9+.-]*:\/\//) {
      sub(/^[A-Za-z][A-Za-z0-9+.-]*:\/\//, "", u)          # scheme
      sub(/^[^\/@]*@/, "", u)                              # userinfo
      slash = index(u, "/"); colon = index(u, ":")         # :port after host
      if (colon > 0 && (slash == 0 || colon < slash)) {
        port = (slash > 0) ? substr(u, colon + 1, slash - colon - 1) : substr(u, colon + 1)
        if (port ~ /^[0-9]+$/) u = substr(u, 1, colon - 1) ((slash > 0) ? substr(u, slash) : "")
      }
    } else {
      sub(/^[^\/@]*@/, "", u)                              # userinfo
      sub(/:/, "/", u)                                     # SCP form: first colon becomes a slash
    }
    while (u ~ /\/$/ || u ~ /\.git$/) { sub(/\/+$/, "", u); sub(/\.git$/, "", u) }
    print tolower(u)
  }')
fi

sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }

printf '%s\n' "$canonical"
printf '%s' "$canonical" | sha256 | cut -c1-20
