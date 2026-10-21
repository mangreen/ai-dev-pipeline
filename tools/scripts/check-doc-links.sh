#!/usr/bin/env bash
# Verify that every relative Markdown link in a directory tree points to an existing file.
# usage: check-doc-links.sh [root]   (default: current directory)
#
# Skipped on purpose: external URLs, mailto:, pure #anchors, and anything inside fenced code
# blocks or inline code (templates contain example links that are not meant to resolve).
# Anchors inside a target file are not validated, only that the file exists.
# Exit codes: 0 all links resolve, 1 broken links found, 2 usage error.
set -uo pipefail

root="${1:-.}"
[ -d "$root" ] || { echo "not a directory: $root" >&2; exit 2; }
root="$(cd "$root" && pwd)"
errors=0

# Print every link target of one Markdown file, with code fences and inline code removed.
links_of() {
  awk '
    /^[[:space:]]*(```|~~~)/ { infence = !infence; next }
    !infence { gsub(/`[^`]*`/, ""); print }
  ' "$1" | grep -oE '\]\([^)]+\)' | sed -e 's/^\](//' -e 's/)$//' || true
}

while IFS= read -r file; do
  dir="$(dirname "$file")"
  while IFS= read -r raw; do
    target="${raw%% *}"          # drop an optional "title"
    case "$target" in
      ""|http://*|https://*|mailto:*|\#*) continue ;;
    esac
    path="${target%%#*}"         # drop the #anchor
    [ -n "$path" ] || continue
    if [[ $path == /* ]]; then resolved="$root$path"; else resolved="$dir/$path"; fi
    if [ ! -e "$resolved" ]; then
      echo "BROKEN LINK ${file#"$root"/}: $target" >&2
      errors=$((errors + 1))
    fi
  done < <(links_of "$file")
done < <(find "$root" -type f -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*' | sort)

[ "$errors" -eq 0 ] || { echo "$errors broken link(s)" >&2; exit 1; }
echo "doc links ok"
