#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit): in GitHub Actions, the agent may not change the
# files that define its own rules or the pipeline. Humans editing locally are not affected.
set -uo pipefail
# Always drain stdin first: exiting before the caller finished writing would make the caller
# die with SIGPIPE (a race that made the hook tests flaky).
input="$(cat)"
[ "${GITHUB_ACTIONS:-}" = "true" ] || exit 0

path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -n "$path" ] || exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${path#"$root"/}"; rel="${rel#./}"

case "$rel" in
  .github/*|.claude/*|CLAUDE.md|CLAUDE.pipeline.md|tools/prompts/*|tools/scripts/*)
    echo "Blocked: $rel is protected in CI. Describe the change you need in the PR instead; a human will make it." >&2
    exit 2 ;;
esac
exit 0
