# ADR-0004: Agent least privilege and untrusted-input stance

- Date: 2026-10-21
- Status: Accepted
- Related: [MEM-0003](../../.agents/memories/MEM-0003-agent-least-privilege-and-untrusted-input.md)

## Context

Agents read issue and pull-request text written by many people (and, in public repositories,
strangers) and can run shell commands with a repository token. Prompt injection cannot be fully
prevented, so the design must limit the damage.

## Options considered

1. Trust the model and the prompt wording.
2. Strict per-stage tool allowlists, minimal token permissions, input never expanded into
   scripts or prompts, protected paths, secret hooks, human gates.
3. Run agents in an isolated network-less sandbox.

## Decision

Option 2 now; option 3 is a future hardening step for sensitive repositories.

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Trust | Simple | Unacceptable blast radius |
| 2 Layered controls | Cheap, testable, uses documented action features | Residual risk inside the allowlist; hooks are guard-rails, not a security boundary |
| 3 Sandbox | Strongest isolation | Extra infrastructure; conflicts with the "no servers" goal |

Reason: defence in depth with controls that are enforced by tests (`workflows_static.test.sh`)
and platform features, while accepting that the final protection is the human review at gates 1
and 2.

## Consequences

- Prompts receive only numbers; the agent fetches text with `gh`.
- Plan and review agents are read-only; the implement agent has enumerated `git` commands, no
  force push, no merge, no `gh api`.
- In CI the agent cannot change `.github/`, `.claude/`, `CLAUDE.md`, `tools/`.
- Use private repositories; never set `allowed_non_write_users` to `*`.
- Residual: an injected instruction could still make the agent write bad code in a PR; reviewers
  must read the diff, which the PR template reminds them to do.
