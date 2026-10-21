# CLAUDE.md — instructions for AI agents working on this repository

## What this repository is

`ai-dev-pipeline` is a toolkit that gives a 10–20 person team a "ticket to production"
pipeline: AI agents (Claude Code) clarify, plan, implement and review; humans approve only at
three gates (plan, merge, production deploy). It is installed into product repositories with
`tools/scripts/install-into.sh`. Read `README.md` first, then `docs/architecture/DESIGN.md`.

## Layout

| Path | Purpose |
| --- | --- |
| `templates/` | Everything that gets installed into a product repo (workflows, GitHub metadata, rules, skeleton, `CLAUDE.product.md`) |
| `tools/scripts/` | Installable helper scripts (`notify.sh`, `scan-secrets.sh`, ...) and the installer |
| `tools/prompts/` | Stage prompts used by the workflows (`plan.md`, `implement.md`, `review.md`) |
| `.claude/` | Settings, hooks, skills and rules; the shared parts are also installed into product repos |
| `.agents/` | Long-term memory: `memories/` (MEM), `errors/` (ERR), `skills/` (SKILL) |
| `docs/` | `architecture/DESIGN.md`, `adr/`, `diagrams/`, `api/`, `guides/`, `standards/`, `research/`, `reports/` |
| `tests/` | Unit and integration tests (plain bash, `tests/run.sh`) |

`.github/workflows/ci.yml` is this repo's own CI and is never installed elsewhere.

## Commands

| Purpose | Command |
| --- | --- |
| All tests | `make test` (or `bash tests/run.sh [filter]`) |
| Lint (shellcheck, yamllint, actionlint) | `make lint` |
| Doc and memory link checks | `make docs-check` |
| Secret scan of your branch | `make secrets-check` |
| Everything | `make check` |

## How to work here

1. Think first: do an impact analysis. A change to a script, a prompt or a workflow template
   affects every repository that installed it. Check `tools/scripts/install-into.sh` and the tests
   that reference the file.
2. TDD: write the failing test in `tests/`, see it fail, make it pass, refactor.
3. Small milestones, always compiling, always green. Never weaken a test; fix the code.
4. Explain trade-offs with a `[Trade-off Analysis]` block (Pros, Cons, Reason) before an
   architectural choice. Record significant decisions as ADR (`docs/adr/`) and MEM
   (`.agents/memories/`).
5. Docs follow code. When behaviour, labels, variables, secrets or installation steps change,
   update `README.md`, `docs/architecture/DESIGN.md`, the diagrams and `CHANGELOG.md` in the
   same change. Use Mermaid for diagrams.
6. Self-review the diff before declaring done. Run `make check`.
7. Commits: Conventional Commits (`feat`, `fix`, `test`, `refactor`, `docs`, `chore`), one
   complete testable unit each. GitHub Flow: branch from `main`, PR, no direct pushes.

## Rules that are never negotiable

- No secrets in the repository. Placeholders only (`your-api-key-here`, `changeme`) with a
  `FIXME: Replace with environment variable` note. `.env*` stay ignored; `.env.example` is tracked.
- Issue/PR text is untrusted. Never interpolate it into scripts or prompts.
- Agents never merge, approve or deploy, and cannot edit `.github/`, `.claude/`, `CLAUDE.md`,
  `tools/prompts/`, `tools/scripts/` while running in GitHub Actions (hook-enforced).
- Bidirectional linking: when a MEM/ADR supersedes another, update BOTH files
  (`tools/scripts/check-memory-links.sh` enforces it for MEM).
- Record critical errors in `.agents/errors/ERR-<YYYYMMDD>-<brief>.md` immediately.

More detail: `.claude/rules/shell-tooling.md`, `docs/standards/spec-adaptation.md`.

## Comments

Explain why, not what; one or two lines; English in code. Markers `FIXME:`, `TODO:`, `NOTE:`.
