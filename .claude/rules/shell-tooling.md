# Shell tooling rules (this repository only)

This repository is shell scripts, GitHub workflow templates and documents. There is no
application `src/` tree, so the Clean Architecture layers do not apply (see
`docs/standards/spec-adaptation.md`).

- Scripts are bash and must pass `shellcheck -x`. Use `set -uo pipefail`; add `-e` only where
  every command is allowed to abort the script. Notification code must never fail the pipeline.
- Require nothing beyond bash >= 4, jq, curl, git, python3 (PyYAML for tests).
- Hooks and scripts that read stdin must read ALL of it before they exit early (see
  `.agents/errors/ERR-20261021-hook-exits-before-draining-stdin.md`).
- Never print secrets or webhook URLs. A webhook URL is a credential.
- Untrusted text (issue titles, PR bodies, comments) must never be expanded into `run:` scripts
  or prompts. Pass it through `env:` or read it via `gh` inside the agent.
- Tests: `tests/unit` (fast, no network, dry-run) and `tests/integration` (local mock webhook,
  fake `gh`, temporary git repos). Write the failing test first. Test names are
  `should_<expected_behavior>_when_<trigger_condition>`.
- Fake secrets in tests are assembled at runtime (`tests/helpers/lib.sh`) so the repository never
  contains a realistic credential literal.
- Code comments are in English; documentation and user-facing notification text are in
  Traditional Chinese (zh-TW).
- Every new workflow job needs `permissions`, `timeout-minutes` (AI jobs) and, for agent
  workflows, a `concurrency` group. `tests/integration/workflows_static.test.sh` enforces this.
