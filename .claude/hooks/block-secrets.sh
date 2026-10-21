#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit): refuse content that looks like a hard-coded secret.
# Exit 2 blocks the tool call and shows stderr to the model.
# Uses the same rules as tools/scripts/scan-secrets.sh (single source of truth).
# NOTE: this is a guard-rail, not a security boundary - shell redirection bypasses it.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scanner="$here/../../tools/scripts/scan-secrets.sh"

input="$(cat)"
path="$(jq -r '.tool_input.file_path // "unknown"' <<<"$input")"
content="$(jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits[]?.new_string)] | map(select(. != null)) | join("\n")' <<<"$input")"
[ -n "$content" ] || exit 0

lines="$(printf '%s\n' "$content" | wc -l | tr -d ' ')"
if ! { printf -- '--- a/%s\n+++ b/%s\n@@ -0,0 +1,%s @@\n' "$path" "$path" "$lines"
       printf '%s\n' "$content" | sed 's/^/+/'; } | bash "$scanner" --stdin >/dev/null 2>&1; then
  echo "Blocked: the content for $path looks like a hard-coded secret." >&2
  echo "Read it from an environment variable and document it in .env.example (placeholder: 'your-api-key-here')." >&2
  exit 2
fi
exit 0
