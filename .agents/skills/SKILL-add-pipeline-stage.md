# SKILL: Add a stage or a notification to the pipeline
Version: 1.0
Domain: development of this toolkit

## When to Use
Adding a workflow, a label, a prompt or a notification event.

## Steps
1. Impact analysis: list the templates, tests, docs and the installer entries that reference the
   thing you change ([docs/architecture/DESIGN.md](../../docs/architecture/DESIGN.md), section "Impact graph").
2. Write the failing test first (`tests/integration/workflows_static.test.sh` for guard-rails,
   `workflow_notify_steps.test.sh` for notifications, `install_into.test.sh` for new files).
3. Add the template under `templates/`. Give every job `permissions`, `timeout-minutes` and, for
   agent workflows, the `ai-issue-<n>` concurrency group. Pass only numbers into prompts.
4. Add the prompt under `tools/prompts/` if an agent is involved.
5. Update labels in `tools/scripts/setup-labels.sh` and its test.
6. Update the state diagram, DESIGN.md, README and CHANGELOG; add an ADR/MEM if it is a
   significant decision.
7. `make check`.

## Caveats
- Do not give the agent merge or approve rights; the static test will fail.
- Labels added by `GITHUB_TOKEN` do not trigger workflows (see ERR-20261021-github-token-events-do-not-trigger-workflows.md).

## Example
The notification jobs in `templates/workflows/ai-plan.yml`.
