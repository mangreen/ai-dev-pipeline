#!/usr/bin/env bash
# Test runner: executes every `should_*` function found in tests/{unit,integration}/*.test.sh
# Each test runs in its own subshell with its own temp dir.
# usage: tests/run.sh [name-filter]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
filter="${1:-}"
pass=0; failed=()

for file in "$ROOT"/tests/unit/*.test.sh "$ROOT"/tests/integration/*.test.sh; do
  [ -e "$file" ] || continue
  for fn in $(grep -oE '^should_[A-Za-z0-9_]+\(\)' "$file" | tr -d '()' | sort -u); do
    [ -n "$filter" ] && [[ "$fn" != *"$filter"* && "$file" != *"$filter"* ]] && continue
    tmp="$(mktemp -d)"
    out="$(
      (
        set -e
        export ROOT TMP="$tmp"
        # shellcheck disable=SC1091
        source "$ROOT/tests/helpers/assert.sh"
        # shellcheck disable=SC1091
        source "$ROOT/tests/helpers/lib.sh"
        trap 'stop_mock; rm -rf "$TMP"' EXIT
        # shellcheck disable=SC1090
        source "$file"
        "$fn"
      ) 2>&1
    )"
    rc=$?
    rm -rf "$tmp"
    # shellcheck disable=SC2001  # multi-line output: a prefix per line needs sed
    if [ "$rc" -eq 0 ]; then
      pass=$((pass + 1)); echo "  ok   $(basename "$file") :: $fn"
    else
      failed+=("$(basename "$file") :: $fn"); echo "  FAIL $(basename "$file") :: $fn"; echo "$out" | sed 's/^/       /'
    fi
  done
done

echo; echo "passed: $pass  failed: ${#failed[@]}"
[ "${#failed[@]}" -eq 0 ]
