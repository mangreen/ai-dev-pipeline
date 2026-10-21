# ERR: Hook exits before reading stdin and makes callers die with SIGPIPE
Date: 2026-10-21
Severity: High

## Description
`should_allow_write_to_workflows_when_not_running_in_github_actions` failed in about 8% of
runs (2 of 25 in a stress loop) although the hook behaved correctly.

## Root Cause
`.claude/hooks/protect-paths.sh` returned `exit 0` outside GitHub Actions BEFORE reading stdin.
The test pipes `jq` into the hook with `pipefail` active, so when the hook had already exited
the writer received SIGPIPE (status 141) and the pipeline, and with it the test, failed. A real
runner has the same race: a tool that writes the hook input can fail if the hook exits first.

## Solution
Read stdin first (`input="$(cat)"`), then decide whether to exit. After the fix 0 failures in 60
runs.

## Prevention
Every hook and filter script drains its input before any early exit. Stress-test suspected
flaky tests in a loop (`for i in $(seq 1 50); do bash tests/run.sh <name>; done`) before
declaring them fixed. Rule recorded in `.claude/rules/shell-tooling.md`.
