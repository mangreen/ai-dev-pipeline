#!/usr/bin/env bash
# Unit tests for Claude Code PreToolUse hooks. Hooks read JSON on stdin and
# signal "block" with exit code 2 (stderr is shown to the model).

BLOCK="$ROOT/.claude/hooks/block-secrets.sh"
PROTECT="$ROOT/.claude/hooks/protect-paths.sh"

json_write() { jq -n --arg p "$1" --arg c "$2" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}'; }
json_edit()  { jq -n --arg p "$1" --arg c "$2" '{tool_name:"Edit",tool_input:{file_path:$p,old_string:"x",new_string:$c}}'; }
json_multi() { jq -n --arg p "$1" --arg c "$2" '{tool_name:"MultiEdit",tool_input:{file_path:$p,edits:[{old_string:"x",new_string:$c}]}}'; }
run_hook() { local hook="$1"; shift; set +e; out="$("$@" bash "$hook" 2>&1)"; rc=$?; set -e; }

should_block_write_when_content_contains_password_literal() {
  json_write src/app.ts "$(fake_password_line)" | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; echo "$out" >"$TMP/out"; }
  assert_eq 2 "$(cat "$TMP/rc")"; assert_contains "$(cat "$TMP/out")" "secret"
}

should_block_edit_when_new_string_contains_private_key_header() {
  json_edit src/k.ts "$(fake_pem_header)" | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_block_multiedit_when_any_edit_contains_secret() {
  json_multi src/k.ts "$(fake_apikey_line)" | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_allow_write_when_content_uses_placeholder() {
  json_write .env.example "API_KEY=\"your-api-key-here\"" | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 0 "$(cat "$TMP/rc")"
}

should_allow_write_when_content_is_clean() {
  json_write src/a.ts "export const add = (a: number, b: number) => a + b;" | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 0 "$(cat "$TMP/rc")"
}

should_allow_when_tool_input_has_no_content_fields() {
  echo '{"tool_name":"Read","tool_input":{"file_path":"a"}}' | { run_hook "$BLOCK" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 0 "$(cat "$TMP/rc")"
}

should_block_write_to_workflows_when_running_in_github_actions() {
  json_write .github/workflows/ci.yml "name: x" | { run_hook "$PROTECT" env -i PATH="$PATH" GITHUB_ACTIONS=true; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_block_write_to_claude_md_when_running_in_github_actions() {
  json_write CLAUDE.md "x" | { run_hook "$PROTECT" env -i PATH="$PATH" GITHUB_ACTIONS=true; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_block_write_to_claude_settings_when_running_in_github_actions() {
  json_write .claude/settings.json "{}" | { run_hook "$PROTECT" env -i PATH="$PATH" GITHUB_ACTIONS=true; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_block_protected_path_when_given_as_absolute_path_inside_project() {
  json_write "/work/repo/.github/workflows/ci.yml" "x" | { run_hook "$PROTECT" env -i PATH="$PATH" GITHUB_ACTIONS=true CLAUDE_PROJECT_DIR=/work/repo; echo "$rc" >"$TMP/rc"; }
  assert_eq 2 "$(cat "$TMP/rc")"
}

should_allow_write_to_source_when_running_in_github_actions() {
  json_write src/app.ts "x" | { run_hook "$PROTECT" env -i PATH="$PATH" GITHUB_ACTIONS=true; echo "$rc" >"$TMP/rc"; }
  assert_eq 0 "$(cat "$TMP/rc")"
}

should_allow_write_to_workflows_when_not_running_in_github_actions() {
  json_write .github/workflows/ci.yml "x" | { run_hook "$PROTECT" env -i PATH="$PATH"; echo "$rc" >"$TMP/rc"; }
  assert_eq 0 "$(cat "$TMP/rc")"
}
