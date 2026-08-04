#!/bin/sh
# Derive the Walkthrough repository ID for the git repository at $1 (default: cwd).
# Prints two lines: the canonical identity string, then the 20-hex-char ID.
# Every client must produce identical output for the same repository.
set -eu

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

if [ -z "$url" ]; then
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

printf '%s\n' "$canonical"
printf '%s' "$canonical" | shasum -a 256 | cut -c1-20
