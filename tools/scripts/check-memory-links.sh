#!/usr/bin/env bash
# Enforce the standard's "bidirectional linking" rule for MEM documents.
# usage: check-memory-links.sh [dir]   (default .agents/memories)
#
# Status line values (separated by `;` or `,`):
#   Approved | Deprecated | Superseded by <MEM file> | Supersedes <MEM file>
set -uo pipefail
((BASH_VERSINFO[0] >= 4)) || { echo "bash >= 4 is required (macOS: brew install bash)" >&2; exit 2; }

dir="${1:-.agents/memories}"
errors=0
err() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }

declare -A superseded_by=() supersedes=() seq_seen=()
shopt -s nullglob

for f in "$dir"/*.md; do
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue

  if ! [[ $base =~ ^MEM-([0-9]{4})-[a-z0-9-]+\.md$ ]]; then
    err "$base: file name must match MEM-NNNN-topic.md (four-digit sequence, lowercase topic)"; continue
  fi
  seq="${BASH_REMATCH[1]}"
  if [ -n "${seq_seen[$seq]:-}" ]; then err "$base: duplicate sequence number $seq (also ${seq_seen[$seq]})"; fi
  seq_seen[$seq]="$base"

  status="$(grep -m1 '^Status:' "$f" | sed 's/^Status:[[:space:]]*//')"
  if [ -z "$status" ]; then err "$base: missing Status line"; continue; fi

  # shellcheck disable=SC2020  # both separators (; and ,) are mapped to a newline on purpose
  while IFS= read -r token; do
    token="$(echo "$token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    case "$token" in
      Approved|Deprecated) ;;
      "Superseded by "*)   superseded_by[$base]="${token#Superseded by }" ;;
      "Supersedes "*)      supersedes[$base]+=" ${token#Supersedes }" ;;
      "")                  ;;
      *) err "$base: unknown Status token '$token'" ;;
    esac
  done < <(echo "$status" | tr ';,' '\n\n')
done

for old in "${!superseded_by[@]}"; do
  new="${superseded_by[$old]}"
  if [ ! -f "$dir/$new" ]; then err "$old: superseded by missing file $new"; continue; fi
  [[ " ${supersedes[$new]:-} " == *" $old "* ]] || err "$new: must declare 'Supersedes $old' (bidirectional linking)"
  grep -q 'DEPRECATED: Superseded by' "$dir/$old" || err "$old: Summary must contain 'DEPRECATED: Superseded by [new MEM]'"
done

for new in "${!supersedes[@]}"; do
  for old in ${supersedes[$new]}; do
    if [ ! -f "$dir/$old" ]; then err "$new: supersedes missing file $old"; continue; fi
    [ "${superseded_by[$old]:-}" = "$new" ] || err "$old: must be marked 'Superseded by $new' (bidirectional linking)"
    grep -q 'Updates/Supersedes' "$dir/$new" || err "$new: Summary must contain 'Updates/Supersedes [old MEM]'"
  done
done

[ "$errors" -eq 0 ] || { echo "$errors problem(s) found" >&2; exit 1; }
echo "memory links ok"
