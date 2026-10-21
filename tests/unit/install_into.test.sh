#!/usr/bin/env bash
# Unit tests for tools/scripts/install-into.sh (adopt the pipeline in a product repo).

INSTALL="$ROOT/tools/scripts/install-into.sh"

should_copy_pipeline_files_when_target_is_an_empty_repo() {
  mkdir "$TMP/t"
  bash "$INSTALL" "$TMP/t" >/dev/null
  assert_file_exists "$TMP/t/.github/workflows/ai-plan.yml"
  assert_file_exists "$TMP/t/.github/workflows/ai-implement.yml"
  assert_file_exists "$TMP/t/.github/workflows/ai-review.yml"
  assert_file_exists "$TMP/t/.github/workflows/claude.yml"
  assert_file_exists "$TMP/t/.github/workflows/deploy.yml"
  assert_file_exists "$TMP/t/.github/notify-owners.json"
  assert_file_exists "$TMP/t/.github/ISSUE_TEMPLATE/ai-task.yml"
  assert_file_exists "$TMP/t/tools/scripts/notify.sh"
  assert_file_exists "$TMP/t/tools/prompts/plan.md"
  assert_file_exists "$TMP/t/.claude/hooks/block-secrets.sh"
  assert_file_exists "$TMP/t/.claude/settings.json"
  assert_file_exists "$TMP/t/CLAUDE.md"
  assert_file_exists "$TMP/t/.agents/memories/README.md"
  assert_file_exists "$TMP/t/docs/adr/0000-template.md"
  [ -x "$TMP/t/tools/scripts/notify.sh" ] || fail "notify.sh must stay executable"
}

should_not_copy_repo_specific_files_when_installing() {
  mkdir "$TMP/t"
  bash "$INSTALL" "$TMP/t" >/dev/null
  assert_file_missing "$TMP/t/.github/workflows/ci.yml"
  assert_file_missing "$TMP/t/tests/run.sh"
  assert_file_missing "$TMP/t/docs/architecture/DESIGN.md"
  assert_file_missing "$TMP/t/.claude/rules/shell-tooling.md"
}

should_install_product_claude_md_when_target_has_none() {
  mkdir "$TMP/t"
  bash "$INSTALL" "$TMP/t" >/dev/null
  assert_contains "$(cat "$TMP/t/CLAUDE.md")" "Hexagonal"
}

should_keep_existing_files_when_force_is_not_given() {
  mkdir -p "$TMP/t/.github/workflows"; echo "MINE" > "$TMP/t/.github/workflows/ai-plan.yml"
  out="$(bash "$INSTALL" "$TMP/t" 2>&1)"
  assert_eq "MINE" "$(cat "$TMP/t/.github/workflows/ai-plan.yml")"
  assert_contains "$out" "skipped"
}

should_write_claude_pipeline_md_when_target_already_has_claude_md() {
  mkdir "$TMP/t"; echo "EXISTING" > "$TMP/t/CLAUDE.md"
  bash "$INSTALL" "$TMP/t" >/dev/null
  assert_eq "EXISTING" "$(cat "$TMP/t/CLAUDE.md")"
  assert_file_exists "$TMP/t/CLAUDE.pipeline.md"
}

should_overwrite_existing_files_when_force_is_given() {
  mkdir -p "$TMP/t/.github/workflows"; echo "MINE" > "$TMP/t/.github/workflows/ai-plan.yml"
  bash "$INSTALL" --force "$TMP/t" >/dev/null
  assert_not_contains "$(cat "$TMP/t/.github/workflows/ai-plan.yml")" "MINE"
}

should_not_touch_target_when_dry_run_is_requested() {
  mkdir "$TMP/t"
  out="$(bash "$INSTALL" --dry-run "$TMP/t")"
  assert_eq 0 "$(find "$TMP/t" -type f | wc -l | tr -d ' ')"
  assert_contains "$out" "would copy"
}

should_fail_when_target_directory_does_not_exist() {
  set +e; bash "$INSTALL" "$TMP/nope" >/dev/null 2>&1; rc=$?; set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit"
}
