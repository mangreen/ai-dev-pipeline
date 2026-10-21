#!/usr/bin/env bash
# Unit tests for tools/scripts/notify.sh using NOTIFY_DRY_RUN (no network).
# Dry run prints one JSON line per platform: {"platform": "...", "payload": {...}}

NOTIFY="$ROOT/tools/scripts/notify.sh"

run_notify() { # extra env assignments are passed as arguments: VAR=value ...
  env MAP_FILE="$TMP/map.json" NOTIFY_DRY_RUN=1 \
    TITLE="Plan ready" URL="https://example.test/issues/1" "$@" bash "$NOTIFY" 2>"$TMP/stderr"
}
slack_text()  { jq -r 'select(.platform=="slack") | .payload.text'; }
teams_card()  { jq -c 'select(.platform=="teams") | .payload.attachments[0].content'; }

should_mention_assignee_in_slack_text_when_owner_is_mapped() {
  # Arrange
  write_owner_map "$TMP/map.json"
  # Act
  out="$(run_notify OWNERS="bob-gh" SLACK_WEBHOOK_URL=https://example.invalid/s)"
  # Assert
  assert_contains "$(echo "$out" | slack_text)" "<@U02BBBBBBB>"
}

should_fall_back_to_default_group_when_owner_is_unknown() {
  write_owner_map "$TMP/map.json"
  out="$(run_notify OWNERS="nobody-gh" SLACK_WEBHOOK_URL=https://example.invalid/s)"
  assert_contains "$(echo "$out" | slack_text)" "<@U01AAAAAAA>"
}

should_fall_back_to_default_group_when_owners_is_empty() {
  write_owner_map "$TMP/map.json"
  out="$(run_notify OWNERS="" SLACK_WEBHOOK_URL=https://example.invalid/s)"
  assert_contains "$(echo "$out" | slack_text)" "<@U01AAAAAAA>"
}

should_mention_every_member_when_owner_is_a_group_token() {
  write_owner_map "$TMP/map.json"
  text="$(run_notify OWNERS="group:deploy" SLACK_WEBHOOK_URL=https://example.invalid/s | slack_text)"
  assert_contains "$text" "<@U01AAAAAAA>"
  assert_contains "$text" "<@U02BBBBBBB>"
}

should_mention_each_person_once_when_owner_is_listed_twice() {
  write_owner_map "$TMP/map.json"
  text="$(run_notify OWNERS="bob-gh bob-gh group:deploy" SLACK_WEBHOOK_URL=https://example.invalid/s | slack_text)"
  count="$(grep -o '<@U02BBBBBBB>' <<<"$text" | wc -l | tr -d ' ')"
  assert_eq 1 "$count"
}

should_escape_slack_control_characters_when_title_contains_channel_mention() {
  write_owner_map "$TMP/map.json"
  text="$(run_notify TITLE='hello <!channel> & co' OWNERS="bob-gh" SLACK_WEBHOOK_URL=https://example.invalid/s | slack_text)"
  assert_contains "$text" "&lt;!channel&gt; &amp; co"
  assert_not_contains "$text" "<!channel>"
}

should_not_mention_in_slack_when_user_has_no_slack_id() {
  write_owner_map "$TMP/map.json"
  text="$(run_notify OWNERS="carol-gh" SLACK_WEBHOOK_URL=https://example.invalid/s | slack_text)"
  assert_not_contains "$text" "<@"
}

should_include_teams_mention_entity_when_user_has_email() {
  write_owner_map "$TMP/map.json"
  card="$(run_notify OWNERS="carol-gh" TEAMS_WEBHOOK_URL=https://example.invalid/t | teams_card)"
  assert_eq "carol@example.test" "$(jq -r '.msteams.entities[0].mentioned.id' <<<"$card")"
  assert_eq "<at>Carol Wu</at>" "$(jq -r '.msteams.entities[0].text' <<<"$card")"
  assert_contains "$(jq -r '.body[0].text' <<<"$card")" "<at>Carol Wu</at>"
}

should_include_open_url_action_when_teams_card_is_built() {
  write_owner_map "$TMP/map.json"
  card="$(run_notify OWNERS="bob-gh" TEAMS_WEBHOOK_URL=https://example.invalid/t | teams_card)"
  assert_eq "https://example.test/issues/1" "$(jq -r '.actions[0].url' <<<"$card")"
}

should_skip_platform_when_its_webhook_is_not_configured() {
  write_owner_map "$TMP/map.json"
  out="$(run_notify OWNERS="bob-gh" SLACK_WEBHOOK_URL=https://example.invalid/s)"
  assert_eq 1 "$(echo "$out" | grep -c '"platform":"slack"')"
  assert_eq 0 "$(echo "$out" | grep -c '"platform":"teams"')"
}

should_exit_zero_and_log_when_no_webhook_is_configured() {
  write_owner_map "$TMP/map.json"
  run_notify OWNERS="bob-gh" >/dev/null
  assert_contains "$(cat "$TMP/stderr")" "no webhook configured"
}

should_fail_when_title_is_missing() {
  write_owner_map "$TMP/map.json"
  set +e
  env -u TITLE MAP_FILE="$TMP/map.json" NOTIFY_DRY_RUN=1 URL=https://x bash "$NOTIFY" >/dev/null 2>&1
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit"
}

should_write_structured_json_log_with_trace_id_when_running() {
  write_owner_map "$TMP/map.json"
  run_notify OWNERS="bob-gh" GITHUB_RUN_ID=424242 SLACK_WEBHOOK_URL=https://example.invalid/s >/dev/null
  line="$(grep '^{' "$TMP/stderr" | head -1)"
  assert_eq 424242 "$(jq -r '.trace_id' <<<"$line")"
  assert_contains "$line" '"ts"'
}
