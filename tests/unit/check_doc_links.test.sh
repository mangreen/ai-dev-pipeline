#!/usr/bin/env bash
# Unit tests for tools/scripts/check-doc-links.sh (relative Markdown links must resolve).

CHECK="$ROOT/tools/scripts/check-doc-links.sh"

doc() { mkdir -p "$(dirname "$TMP/d/$1")"; printf '%s\n' "$2" > "$TMP/d/$1"; }
check() { bash "$CHECK" "$TMP/d" 2>&1; }

should_pass_when_relative_link_points_to_existing_file() {
  doc a.md "see [b](b.md)"; doc b.md "# b"
  check
}

should_fail_when_relative_link_points_to_missing_file() {
  doc a.md "see [gone](gone.md)"
  set +e; out="$(check)"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "a.md"; assert_contains "$out" "gone.md"
}

should_ignore_external_and_anchor_only_links_when_checking() {
  doc a.md "[x](https://example.test/x) [y](#section) [m](mailto:a@example.test)"
  check
}

should_accept_link_with_anchor_when_target_file_exists() {
  doc a.md "[b](b.md#part)"; doc b.md "# b"
  check
}

should_resolve_links_relative_to_the_linking_file_when_in_subdirectory() {
  doc docs/a.md "[b](../top.md)"; doc top.md "# top"
  check
}

should_accept_link_to_directory_when_directory_exists() {
  doc a.md "[dir](sub/)"; mkdir -p "$TMP/d/sub"
  check
}

should_ignore_links_inside_code_fences_and_inline_code_when_checking() {
  # NOTE: backticks are literal Markdown here, not command substitution.
  # shellcheck disable=SC2016
  doc a.md '```
[fake](nope.md)
```
and `[inline](nope2.md)` too'
  check
}

should_fail_when_root_directory_does_not_exist() {
  set +e; bash "$CHECK" "$TMP/nope" >/dev/null 2>&1; rc=$?; set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit"
}
