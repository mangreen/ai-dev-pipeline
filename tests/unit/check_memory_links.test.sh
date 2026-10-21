#!/usr/bin/env bash
# Unit tests for tools/scripts/check-memory-links.sh (bidirectional MEM linking rule).

CHECK="$ROOT/tools/scripts/check-memory-links.sh"

mem() { # $1=dir $2=file $3=status line value $4=summary line
  mkdir -p "$1"
  printf '# MEM: Topic\nDate: 2026-10-21\nStatus: %s\nTags: [x]\n\n## Summary\n%s\n\n## Details\n\n## When to Use\n' "$3" "$4" > "$1/$2"
}
check() { bash "$CHECK" "$1" 2>&1; }

should_pass_when_all_documents_are_approved() {
  mem "$TMP/m" MEM-0001-a.md "Approved" "One sentence."
  mem "$TMP/m" MEM-0002-b.md "Approved" "One sentence."
  check "$TMP/m"
}

should_pass_when_supersede_links_are_bidirectional() {
  mem "$TMP/m" MEM-0001-a.md "Superseded by MEM-0002-b.md" "DEPRECATED: Superseded by [MEM-0002-b.md](MEM-0002-b.md)"
  mem "$TMP/m" MEM-0002-b.md "Supersedes MEM-0001-a.md" "Updates/Supersedes [MEM-0001-a.md](MEM-0001-a.md)"
  check "$TMP/m"
}

should_fail_when_new_document_lacks_supersedes_status() {
  mem "$TMP/m" MEM-0001-a.md "Superseded by MEM-0002-b.md" "DEPRECATED: Superseded by [MEM-0002-b.md](MEM-0002-b.md)"
  mem "$TMP/m" MEM-0002-b.md "Approved" "No back link."
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "MEM-0002-b.md"
}

should_fail_when_old_document_is_not_marked_superseded() {
  mem "$TMP/m" MEM-0001-a.md "Approved" "Still looks valid."
  mem "$TMP/m" MEM-0002-b.md "Supersedes MEM-0001-a.md" "Updates/Supersedes [MEM-0001-a.md](MEM-0001-a.md)"
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "MEM-0001-a.md"
}

should_fail_when_superseding_document_does_not_exist() {
  mem "$TMP/m" MEM-0001-a.md "Superseded by MEM-0009-missing.md" "DEPRECATED: Superseded by [x](MEM-0009-missing.md)"
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "MEM-0009-missing.md"
}

should_fail_when_deprecated_summary_lacks_deprecated_notice() {
  mem "$TMP/m" MEM-0001-a.md "Superseded by MEM-0002-b.md" "Forgot the notice."
  mem "$TMP/m" MEM-0002-b.md "Supersedes MEM-0001-a.md" "Updates/Supersedes [MEM-0001-a.md](MEM-0001-a.md)"
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "DEPRECATED"
}

should_fail_when_file_name_violates_pattern() {
  mem "$TMP/m" MEM-1-a.md "Approved" "Bad sequence."
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "MEM-1-a.md"
}

should_fail_when_status_line_is_missing() {
  mkdir -p "$TMP/m"; printf '# MEM: Topic\nDate: 2026-10-21\n' > "$TMP/m/MEM-0001-a.md"
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "Status"
}

should_fail_when_sequence_number_is_duplicated() {
  mem "$TMP/m" MEM-0001-a.md "Approved" "x"
  mem "$TMP/m" MEM-0001-b.md "Approved" "x"
  set +e; out="$(check "$TMP/m")"; rc=$?; set -e
  assert_status 1 "$rc"; assert_contains "$out" "duplicate"
}

should_ignore_readme_when_directory_contains_one() {
  mem "$TMP/m" MEM-0001-a.md "Approved" "x"
  echo "# readme" > "$TMP/m/README.md"
  check "$TMP/m"
}
