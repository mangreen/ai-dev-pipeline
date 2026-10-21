#!/usr/bin/env bash
# Integration tests: notify.sh really POSTs JSON over HTTP to a local mock webhook.

NOTIFY="$ROOT/tools/scripts/notify.sh"

post() {
  env MAP_FILE="$TMP/map.json" TITLE="Plan ready" URL="https://example.test/i/1" TEXT="Please review" \
    OWNERS="bob-gh" "$@" bash "$NOTIFY" >"$TMP/stdout" 2>"$TMP/stderr"
}
all_output() { cat "$TMP/stdout" "$TMP/stderr"; }

should_post_slack_payload_with_mention_when_slack_webhook_is_set() {
  write_owner_map "$TMP/map.json"; start_mock
  post SLACK_WEBHOOK_URL="$MOCK_URL/slack"
  assert_eq 1 "$(wc -l < "$TMP/requests.jsonl" | tr -d ' ')"
  assert_eq "/slack" "$(jq -r .path "$TMP/requests.jsonl")"
  assert_contains "$(jq -r .body.text "$TMP/requests.jsonl")" "<@U02BBBBBBB>"
}

should_post_adaptive_card_when_teams_webhook_is_set() {
  write_owner_map "$TMP/map.json"; start_mock
  post TEAMS_WEBHOOK_URL="$MOCK_URL/teams"
  assert_eq "message" "$(jq -r .body.type "$TMP/requests.jsonl")"
  assert_eq "application/vnd.microsoft.card.adaptive" "$(jq -r '.body.attachments[0].contentType' "$TMP/requests.jsonl")"
}

should_post_to_both_platforms_when_both_webhooks_are_set() {
  write_owner_map "$TMP/map.json"; start_mock
  post SLACK_WEBHOOK_URL="$MOCK_URL/slack" TEAMS_WEBHOOK_URL="$MOCK_URL/teams"
  assert_eq 2 "$(wc -l < "$TMP/requests.jsonl" | tr -d ' ')"
}

should_exit_zero_and_emit_warning_when_webhook_returns_server_error() {
  write_owner_map "$TMP/map.json"; MOCK_STATUS=500 start_mock
  post SLACK_WEBHOOK_URL="$MOCK_URL/slack"
  assert_contains "$(all_output)" "::warning::"
}

should_exit_zero_and_emit_warning_when_webhook_host_is_unreachable() {
  write_owner_map "$TMP/map.json"
  post SLACK_WEBHOOK_URL="http://127.0.0.1:1/none"
  assert_contains "$(all_output)" "::warning::"
}

should_not_leak_webhook_url_in_logs_when_posting() {
  write_owner_map "$TMP/map.json"; start_mock
  post SLACK_WEBHOOK_URL="$MOCK_URL/slack-secret-path"
  assert_not_contains "$(all_output)" "slack-secret-path"
}
