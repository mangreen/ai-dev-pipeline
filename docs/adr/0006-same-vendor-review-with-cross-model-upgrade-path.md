# ADR-0006: Same-vendor review now, cross-model upgrade path

- Date: 2026-10-21
- Status: Accepted
- Related: [DESIGN.md](../architecture/DESIGN.md) section 12

## Context

An AI reviewing AI-written code can share blind spots with the author. A different model family
reduces correlated errors but needs a second vendor account and key.

## Options considered

1. Review with the same vendor (Claude), as a separate run with its own prompt and a stronger
   default model than the implementer.
2. Review with a different vendor (for example `openai/codex-action`).
3. Both.

## Decision

Option 1 by default. The review stage is isolated in `ai-review.yml` and `tools/prompts/review.md`
so that option 2 or 3 is a workflow swap.

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Same vendor | One key, one billing, simplest | Correlated blind spots |
| 2 Other vendor | Independent perspective | Second key, second set of permissions and costs |
| 3 Both | Highest coverage | Highest cost and noise |

Reason: the human at gate 2 is the real control; cross-model review is an optimisation to adopt
after the trial period shows whether review misses matter.

## Consequences

- Reviewer separation is by run, prompt and (default) model, not by vendor.
- Upgrade recipe in the README troubleshooting/roadmap; `codex-action` runs with a read-only
  permission profile and posts its output as a comment in a second job.
