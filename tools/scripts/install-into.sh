#!/usr/bin/env bash
# Install the AI development pipeline into a product repository.
# usage: install-into.sh [--dry-run] [--force] <target-dir>
#
# Copies workflows, issue/PR templates, Claude Code settings/hooks/skills, prompts,
# helper scripts and doc skeletons. Existing files are kept unless --force is given.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
force=0; dry=0; target=""
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) target="$arg" ;;
  esac
done
[ -n "$target" ] || { echo "usage: $0 [--dry-run] [--force] <target-dir>" >&2; exit 2; }
[ -d "$target" ] || { echo "target directory does not exist: $target" >&2; exit 1; }
target="$(cd "$target" && pwd)"

copied=0; skipped=0
copy_file() { # src dst
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ "$force" -eq 0 ]; then
    echo "skipped (exists): ${dst#"$target"/}"; skipped=$((skipped + 1)); return
  fi
  if [ "$dry" -eq 1 ]; then echo "would copy: ${dst#"$target"/}"; copied=$((copied + 1)); return; fi
  mkdir -p "$(dirname "$dst")"; cp -p "$src" "$dst"
  echo "copied: ${dst#"$target"/}"; copied=$((copied + 1))
}
copy_tree() { # src-dir dst-dir
  [ -d "$1" ] || return 0
  local f
  while IFS= read -r f; do copy_file "$f" "$2/${f#"$1"/}"; done < <(find "$1" -type f ! -name '.gitkeep' | sort)
}

# --- pipeline workflows and GitHub metadata
copy_tree "$SRC/templates/workflows" "$target/.github/workflows"
copy_tree "$SRC/templates/github"    "$target/.github"
# --- Claude Code configuration shared with this repository
copy_file "$SRC/.claude/settings.json" "$target/.claude/settings.json"
copy_tree "$SRC/.claude/hooks"  "$target/.claude/hooks"
copy_tree "$SRC/.claude/skills" "$target/.claude/skills"
copy_tree "$SRC/templates/rules" "$target/.claude/rules"
# --- prompts and helper scripts
copy_tree "$SRC/tools/prompts" "$target/tools/prompts"
for s in notify.sh scan-secrets.sh check-memory-links.sh setup-labels.sh; do
  copy_file "$SRC/tools/scripts/$s" "$target/tools/scripts/$s"
done
# --- doc / memory skeleton (.agents, docs/adr template, todo.md, CHANGELOG.md)
copy_tree "$SRC/templates/skeleton" "$target"
# --- project instructions: never clobber an existing CLAUDE.md
if [ -e "$target/CLAUDE.md" ] && [ "$force" -eq 0 ]; then
  copy_file "$SRC/templates/CLAUDE.product.md" "$target/CLAUDE.pipeline.md"
  echo "NOTE: CLAUDE.md already exists; merge CLAUDE.pipeline.md into it by hand."
else
  copy_file "$SRC/templates/CLAUDE.product.md" "$target/CLAUDE.md"
fi

echo "done: $copied file(s) $([ "$dry" -eq 1 ] && echo 'would be copied' || echo copied), $skipped skipped"
