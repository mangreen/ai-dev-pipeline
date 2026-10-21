# MEM: Three human gates enforced by the platform
Date: 2026-10-21
Status: Approved
Tags: [governance, security, github]

## Summary
Humans approve exactly three things - the plan, the merge, the production deployment - and each
gate is enforced by a GitHub feature, not by an agent's good behaviour.

## Details
### Context & Evolution
See [ADR-0002](../../docs/adr/0002-three-human-gates-enforced-by-github.md).

### Specification
| Gate | Human action | Enforced by |
| --- | --- | --- |
| 1 Plan | Add label `plan-approved` | Stage 2 triggers only on that label; the label can only be added by users with triage access or above |
| 2 Merge | Approve and merge the PR | Branch protection / ruleset: required human approval, required status checks, Code Owners for `.github/`, `.claude/`, `tools/` |
| 3 Production | Review deployments | Environment `production` with required reviewers |

Agent jobs have no merge/approve tool in their allowlist (`workflows_static.test.sh` checks it).

## When to Use
Before adding any automation that would skip, auto-approve or bypass one of the gates: do not.
