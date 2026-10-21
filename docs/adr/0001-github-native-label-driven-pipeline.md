# ADR-0001: GitHub-native, label-driven pipeline

- Date: 2026-10-21
- Status: Accepted
- Related: [MEM-0001](../../.agents/memories/MEM-0001-label-driven-github-native-pipeline.md)

## Context

A 10–20 person team wants AI agents to move a ticket to a reviewed pull request with humans at
a few gates. Open-source orchestrators exist (Symphony, Cyrus, Open SWE, Agent Orchestrator),
but each adds a service to operate, and the most prominent ones are early-stage
(see [oss-landscape.md](../research/oss-landscape.md)).

## Options considered

1. GitHub Actions + `anthropics/claude-code-action`, driven by issue labels.
2. Cyrus (self-hosted) with Linear as the tracker.
3. OpenAI Symphony reference implementation.
4. LangChain Open SWE.

## Decision

Option 1 for the base pipeline. Cyrus is the documented upgrade for teams whose tickets must
live in Linear.

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Actions + labels | No server; official action; permissions, branch protection and environments are native; testable | Tickets live in GitHub; Actions minutes; limited UI |
| 2 Cyrus | Assign-to-agent UX in Linear; multi-runner | A service to run or pay for; vendor docs report 3–5x token use; licence/plan details differ between self-hosted and cloud |
| 3 Symphony | Clear spec; tracker-agnostic idea | Documented as an engineering preview for trusted environments; Elixir reference; Codex-centric |
| 4 Open SWE | Rich triggers and sandboxes | README: breaking changes expected; heavy team deployment; not taking external contributions |

Reason: the lowest operational burden that still meets the gate requirements, using products the
team already administers. The decision is reversible: prompts, labels and gates carry over to
other executors.

## Consequences

- Easier: no infrastructure, audit trail in GitHub, security reviewed with existing tools.
- Harder: each stage needs a human to add a label (by design); Jira/Linear need a bridge.
- Monitor: Actions minutes, API spend, plan adoption rate.
