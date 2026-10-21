# MEM: Label-driven, GitHub-native pipeline
Date: 2026-10-21
Status: Approved
Tags: [architecture, pipeline, github-actions]

## Summary
The pipeline is a state machine driven by issue labels and run by GitHub Actions with
`anthropics/claude-code-action`; no server or database is operated by us.

## Details
### Context & Evolution
Open-source orchestrators that poll a tracker (Symphony, Cyrus, Open SWE) exist, but the
leanest option for a 10–20 person team is the platform they already use. Full reasoning and the
trade-off table: [ADR-0001](../../docs/adr/0001-github-native-label-driven-pipeline.md).

### Specification
- Tickets are GitHub issues. Stages are triggered by a human adding a label:
  `ai:plan` (stage 1) and `plan-approved` (stage 2). PR events trigger stage 3.
- The agent records state with labels `needs:clarification` and `needs:plan-approval`.
- Labels added with `GITHUB_TOKEN` do not trigger workflows, therefore only a human can advance
  an issue. Do not "fix" this by using a personal access token for label changes.
- Stage prompts live in `tools/prompts/`; workflows only pass the issue or PR number.
- Deployment is ordinary CI/CD, not an agent.

## When to Use
When changing labels, workflow triggers, prompts or adding a stage. Diagram:
[docs/diagrams/pipeline-state.md](../../docs/diagrams/pipeline-state.md).
