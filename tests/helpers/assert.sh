#!/usr/bin/env bash
# Minimal assertion helpers. Every helper returns non-zero on failure so that
# `set -e` inside the runner aborts the test function.

fail() { echo "    ASSERT FAILED: $*" >&2; return 1; }

assert_eq() { [ "$1" = "$2" ] || fail "expected [$1] but got [$2] ${3:-}"; }

assert_contains() {
  case "$1" in *"$2"*) ;; *) fail "expected to contain [$2] but was [$1]";; esac
}

assert_not_contains() {
  case "$1" in *"$2"*) fail "expected NOT to contain [$2] but was [$1]";; esac
}

assert_status() { [ "$1" -eq "$2" ] || fail "expected exit status $1 but got $2 ${3:-}"; }

assert_file_exists() { [ -e "$1" ] || fail "expected file to exist: $1"; }
assert_file_missing() { [ ! -e "$1" ] || fail "expected file NOT to exist: $1"; }
