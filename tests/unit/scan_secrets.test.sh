#!/usr/bin/env bash
# Unit tests for tools/scripts/scan-secrets.sh (reads a unified diff on stdin).

SCAN="$ROOT/tools/scripts/scan-secrets.sh"

diff_with_added() { # $1 = added line
  printf '%s\n' '--- a/src/app.ts' '+++ b/src/app.ts' '@@ -1,0 +1,1 @@' "+$1"
}
scan() { bash "$SCAN" --stdin; }

should_flag_password_literal_when_added_line_assigns_quoted_password() {
  set +e; out="$(diff_with_added "$(fake_password_line)" | scan 2>&1)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "src/app.ts:1"; assert_contains "$out" "password"
}

should_flag_api_key_literal_when_added_line_assigns_quoted_key() {
  set +e; out="$(diff_with_added "$(fake_apikey_line)" | scan 2>&1)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "api-key"
}

should_flag_openai_style_token_when_long_sk_token_is_added() {
  set +e; out="$(diff_with_added "token = $(fake_sk_token)" | scan 2>&1)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "sk-token"
}

should_flag_private_key_block_when_pem_header_is_added() {
  set +e; out="$(diff_with_added "$(fake_pem_header)" | scan 2>&1)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "private-key"
}

should_not_flag_placeholder_when_value_is_changeme() {
  diff_with_added 'password = "changeme"  // FIXME: Replace with environment variable' | scan
}

should_not_flag_placeholder_when_value_is_your_api_key_here() {
  diff_with_added "const API_KEY = 'your-api-key-here';" | scan
}

should_not_flag_when_value_is_a_variable_reference() {
  # NOTE: the literal ${...} is intentional; it must stay unexpanded to model a config reference.
  # shellcheck disable=SC2016
  diff_with_added 'password: "${DB_PASSWORD}"' | scan
}

should_not_flag_when_word_contains_sk_dash_like_risk_based() {
  # The raw `sk-[a-zA-Z0-9]` pattern from the standard matches "risk-based" (see ERR-20261021).
  diff_with_added 'This is a risk-based approach to task-oriented work.' | scan
}

should_not_flag_when_sk_dash_is_part_of_a_kebab_case_file_name() {
  # A file name such as ERR-20261021-sk-regex-matches-risk-based.md must not look like a token.
  diff_with_added 'see ../../.agents/errors/ERR-20261021-sk-regex-matches-risk-based.md' | scan
}

should_still_flag_token_when_it_follows_an_equals_sign_or_quote() {
  set +e
  diff_with_added "key=$(fake_sk_token)" | scan >/dev/null 2>&1; rc1=$?
  diff_with_added "x = \"$(fake_sk_token)\"" | scan >/dev/null 2>&1; rc2=$?
  set -e
  assert_status 1 "$rc1"; assert_status 1 "$rc2"
}

should_not_flag_when_assignment_value_is_empty() {
  diff_with_added 'password = ""' | scan
}

should_ignore_removed_lines_when_secret_only_exists_in_deleted_line() {
  printf '%s\n' '--- a/src/app.ts' '+++ b/src/app.ts' '@@ -1,1 +0,0 @@' "-$(fake_password_line)" | scan
}

should_not_print_the_secret_value_when_reporting_a_finding() {
  set +e; out="$(diff_with_added "$(fake_password_line)" | scan 2>&1)"; set -e
  assert_not_contains "$out" "Zx9-not-a-real-value"
}

should_report_correct_line_number_when_hunk_starts_later_in_file() {
  set +e
  out="$(printf '%s\n' '--- a/x.ts' '+++ b/x.ts' '@@ -10,0 +42,2 @@' '+const ok = 1;' "+$(fake_password_line)" | scan 2>&1)"
  set -e
  assert_contains "$out" "x.ts:43"
}

should_exit_zero_when_diff_is_clean() {
  diff_with_added 'const total = a + b;' | scan
}
