# ERR: Events created with GITHUB_TOKEN do not trigger other workflows
Date: 2026-10-21
Severity: High

## Description
A pull request opened or a label added with the default `GITHUB_TOKEN` does not start workflows
that listen to `pull_request` or `issues: labeled`. CI and the AI review silently never run on
an AI-authored PR.

## Root Cause
GitHub deliberately suppresses workflow runs for events caused by `GITHUB_TOKEN` to prevent
recursive runs. Documented in the claude-code-action troubleshooting ("CI not running on
Claude's commits").

## Solution
- PRs created by the agent must be authored by the Claude GitHub App token, so do NOT pass
  `github_token: ${{ secrets.GITHUB_TOKEN }}` to `anthropics/claude-code-action`.
- Labels set by the agent through `gh` with `GITHUB_TOKEN` intentionally trigger nothing; that
  keeps the human in control (MEM-0001).
- If the App token is not used for `gh pr create` in your setup, create a GitHub App token with
  `actions/create-github-app-token` and expose it as `GH_TOKEN` to the agent step.

## Prevention
Smoke-test checklist in the README ("Verify") asks: did CI start on the AI PR? Open verification
item V1 in `docs/architecture/DESIGN.md`.
