#!/usr/bin/env bash
# Unit tests for tools/scripts/setup-labels.sh (uses the fake gh).

SETUP="$ROOT/tools/scripts/setup-labels.sh"

should_create_every_pipeline_label_when_run() {
  use_fake_gh; export FAKE_GH_LOG="$TMP/gh.log"
  bash "$SETUP" >/dev/null
  for l in "ai:plan" "needs:clarification" "needs:plan-approval" "plan-approved"; do
    assert_contains "$(cat "$TMP/gh.log")" "label create $l"
  done
}

should_target_given_repository_when_repo_flag_is_passed() {
  use_fake_gh; export FAKE_GH_LOG="$TMP/gh.log"
  bash "$SETUP" --repo acme/shop >/dev/null
  assert_contains "$(cat "$TMP/gh.log")" "--repo acme/shop"
}

should_update_existing_labels_when_run_twice() {
  use_fake_gh; export FAKE_GH_LOG="$TMP/gh.log"
  bash "$SETUP" >/dev/null
  assert_contains "$(cat "$TMP/gh.log")" "--force"
}
