#!/usr/bin/env bash
# Integration: run the `notify` job scripts extracted from the workflow templates,
# with a fake `gh` and a mock webhook, and assert which message would be sent.

WF="$ROOT/templates/workflows"

prepare() {
  mkdir -p "$TMP/work/.github" "$TMP/work/tools"
  cp -R "$ROOT/tools/scripts" "$TMP/work/tools/scripts"
  write_owner_map "$TMP/work/.github/notify-owners.json"
  use_fake_gh; start_mock
}
run_job() { # $1=workflow file $2=job id ; env from caller
  step_script "$WF/$1" "$2" > "$TMP/step.sh"
  [ -s "$TMP/step.sh" ] || fail "no run script found for job $2 in $1"
  ( cd "$TMP/work" && SLACK_WEBHOOK_URL="$MOCK_URL/slack" bash "$TMP/step.sh" ) >/dev/null 2>"$TMP/stderr"
}
# Full text (all lines) of the most recent Slack request.
last_text()  { jq -rs 'map(select(.path == "/slack")) | .[-1].body.text' "$TMP/requests.jsonl"; }
sent_count() { wc -l < "$TMP/requests.jsonl" | tr -d ' '; }

# ---- ai-plan ----
should_notify_assignee_to_approve_plan_when_plan_label_needs_approval() {
  prepare
  N=7 PLAN_RESULT=success RUN_URL=https://run/1 run_job ai-plan.yml notify
  assert_contains "$(last_text)" "<@U02BBBBBBB>"
  assert_contains "$(last_text)" "計畫待審核"
}

should_ask_for_clarification_when_plan_label_needs_clarification() {
  prepare
  FAKE_LABEL=needs:clarification N=7 PLAN_RESULT=success RUN_URL=https://run/1 run_job ai-plan.yml notify
  assert_contains "$(last_text)" "釐清需求"
}

should_notify_failure_with_run_link_when_plan_job_failed() {
  prepare
  N=7 PLAN_RESULT=failure RUN_URL=https://run/1 run_job ai-plan.yml notify
  assert_contains "$(last_text)" "計畫階段失敗"
  assert_contains "$(last_text)" "https://run/1"
}

should_fall_back_to_issue_author_when_issue_has_no_assignee() {
  prepare
  FAKE_ASSIGNEES='[]' N=7 PLAN_RESULT=success RUN_URL=https://run/1 run_job ai-plan.yml notify
  assert_contains "$(last_text)" "<@U01AAAAAAA>"
}

# ---- ai-implement ----
should_stay_silent_when_implementation_succeeded_and_pr_exists() {
  prepare
  FAKE_PR=1 N=7 IMPL_RESULT=success RUN_URL=https://run/2 run_job ai-implement.yml notify
  assert_eq 0 "$(sent_count)"
}

should_notify_when_implementation_succeeded_but_no_pr_was_opened() {
  prepare
  N=7 IMPL_RESULT=success RUN_URL=https://run/2 run_job ai-implement.yml notify
  assert_contains "$(last_text)" "沒有開 PR"
}

should_notify_when_implementation_failed() {
  prepare
  FAKE_PR=1 N=7 IMPL_RESULT=failure RUN_URL=https://run/2 run_job ai-implement.yml notify
  assert_contains "$(last_text)" "實作失敗"
}

# ---- ai-review ----
should_notify_linked_issue_owner_when_ai_review_succeeded() {
  prepare
  # carol-gh (owner of linked issue #7 in the fake gh) has no Slack ID in the fixture map,
  # so the owner is verified through the Teams mention instead.
  PR=9 REVIEW_RESULT=success TEAMS_WEBHOOK_URL="$MOCK_URL/teams" run_job ai-review.yml notify
  assert_contains "$(last_text)" "待人工審查與合併"
  teams_body="$(jq -c 'select(.path=="/teams") | .body' "$TMP/requests.jsonl")"
  assert_contains "$teams_body" "Carol Wu"
}

should_flag_review_failure_when_ai_review_failed() {
  prepare
  PR=9 REVIEW_RESULT=failure run_job ai-review.yml notify
  assert_contains "$(last_text)" "AI 審查失敗"
}

# ---- deploy ----
should_notify_deploy_group_when_production_awaits_approval() {
  prepare
  OWNERS=group:deploy TITLE="staging ok" URL=https://run/3 run_job deploy.yml notify-approval
  assert_contains "$(last_text)" "<@U01AAAAAAA>"
  assert_contains "$(last_text)" "<@U02BBBBBBB>"
}

should_notify_deploy_group_when_deployment_failed() {
  prepare
  OWNERS=group:deploy TITLE="deploy failed" URL=https://run/3 run_job deploy.yml notify-failure
  assert_contains "$(last_text)" "deploy failed"
}
