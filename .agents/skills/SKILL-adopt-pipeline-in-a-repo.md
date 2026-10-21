# SKILL: Adopt the pipeline in a product repository
Version: 1.0
Domain: onboarding

## When to Use
A team wants the ticket-to-production pipeline in an existing repository.

## Steps
1. Dry run: `bash tools/scripts/install-into.sh --dry-run <target>` and read the list.
2. Install: `bash tools/scripts/install-into.sh <target>` (existing files are kept; use
   `--force` only for files you have not customised).
3. In the target: fill `FIXME(setup)` in `CLAUDE.md`, edit `.github/notify-owners.json`,
   `.github/CODEOWNERS`.
4. `bash tools/scripts/setup-labels.sh --repo <owner/name>`.
5. Configure secrets (`ANTHROPIC_API_KEY`, `SLACK_WEBHOOK_URL`/`TEAMS_WEBHOOK_URL`) and variables
   (`AI_SETUP_CMD`, `AI_TEST_TOOLS`, `DEPLOY_ENABLED`). Install the Claude GitHub App.
6. Configure branch protection and the `production` environment reviewers.
7. Run the smoke test from the README with a tiny ticket.

## Caveats
- Run the smoke test in a sandbox repository first.
- The installer never overwrites `CLAUDE.md`; it writes `CLAUDE.pipeline.md` to merge by hand.

## Example
README section "安裝步驟".
