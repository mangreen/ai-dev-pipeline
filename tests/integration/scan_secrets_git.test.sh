#!/usr/bin/env bash
# Integration: scan-secrets.sh --base <ref> against a real temporary git repository.

SCAN="$ROOT/tools/scripts/scan-secrets.sh"

new_repo() {
  git init -q -b main "$TMP/r"; cd "$TMP/r"
  git config user.email t@example.test; git config user.name t
  echo "base" > a.txt; git add a.txt; git commit -qm "chore: base"
}

should_exit_one_when_branch_adds_a_secret_literal() {
  new_repo
  git checkout -qb feature/x; fake_password_line > app.ts; git add app.ts; git commit -qm "feat: x"
  set +e; out="$(bash "$SCAN" --base main 2>&1)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "app.ts:1"
}

should_exit_zero_when_branch_adds_only_clean_code() {
  new_repo
  git checkout -qb feature/x; echo "export const a = 1;" > app.ts; git add app.ts; git commit -qm "feat: x"
  bash "$SCAN" --base main
}

should_ignore_secrets_that_exist_only_on_base_when_scanning_branch_diff() {
  new_repo
  fake_password_line > old.ts; git add old.ts; git commit -qm "chore: legacy"
  git checkout -qb feature/x; echo "export const a = 1;" > app.ts; git add app.ts; git commit -qm "feat: x"
  bash "$SCAN" --base main
}

should_fail_with_usage_when_no_mode_is_given() {
  set +e; bash "$SCAN" >/dev/null 2>&1; rc=$?; set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit"
}
