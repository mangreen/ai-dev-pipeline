# Changelog

All notable changes are recorded here, newest first. Format: Keep a Changelog.
Versioning: Git tags (`v0.1.0`).

## [Unreleased]

## [0.1.0] - 2026-10-21

### Added

- Pipeline workflow templates: `ai-plan`, `ai-implement`, `ai-review`, `claude`, `deploy`
  (label-driven; three human gates; deployment is deterministic CI/CD).
- Stage prompts in `tools/prompts/` and repository variables for setup command, test tool
  allowlist and per-stage models.
- `tools/scripts/notify.sh`: Slack and Teams notifications that mention the owner, with an owner
  map and structured JSON logs.
- Guard-rails: `scan-secrets.sh`, Claude Code hooks (`block-secrets`, `protect-paths`),
  `check-memory-links.sh` (bidirectional MEM links), `check-doc-links.sh`, `setup-labels.sh`.
- `install-into.sh` to adopt the pipeline in a product repository (`--dry-run`, `--force`).
- Product templates: `CLAUDE.product.md`, rules (testing, security, git, comments), skeleton
  (`.agents/`, ADR template, `todo.md`, `CHANGELOG.md`), issue form, PR template, CODEOWNERS.
- Design document, 7 ADRs, Mermaid diagrams, notification contract, guides, research summary,
  standards adaptation, MEM/ERR/SKILL records.
- CI for this repository (shellcheck, yamllint, actionlint, tests, doc checks, secret scans).

### Fixed

- `protect-paths.sh` exited before reading stdin, which made the hook tests fail about 8% of the
  time (`ERR-20261021-hook-exits-before-draining-stdin`).
- Workflow-step tests read only the last line of a multi-line Slack message and expected a Slack
  ID that did not exist in the fixture.
- Dry-run mode of `notify.sh` now emits the structured log line like a real send.
