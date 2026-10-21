# ADR-0002: Three human gates enforced by GitHub features

- Date: 2026-10-21
- Status: Accepted
- Related: [MEM-0002](../../.agents/memories/MEM-0002-three-human-gates.md)

## Context

Requirement: humans intervene only where necessary - whether to execute a plan, whether to merge
a PR, whether to release to production. A prompt that says "wait for approval" is not a control;
an agent can be misled. The gates must hold even if the agent misbehaves.

## Options considered

1. Gates described in prompts only.
2. Gates implemented by custom code (a bot that tracks approvals).
3. Gates enforced by platform features: label-triggered stages, rulesets, environment reviewers.

## Decision

Option 3.

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Prompt only | Trivial | Not enforceable; defeated by prompt injection |
| 2 Custom bot | Flexible rules | New code and service to secure and maintain |
| 3 Platform features | Enforced outside the agent; audited by GitHub; zero code | Needs correct repository settings; some features depend on the GitHub plan for private repositories |

Reason: controls must live outside the thing being controlled. Gate 1 relies on the fact that
labels added by `GITHUB_TOKEN` do not trigger workflows, so only a human can start stage 2.

## Consequences

- The README makes repository settings an installation step and a smoke-test item.
- A static test forbids merge/approve/`gh api` in agent workflows.
- Verification item V6 (plan support for rulesets/environments) stays open until the team checks
  its GitHub plan.
