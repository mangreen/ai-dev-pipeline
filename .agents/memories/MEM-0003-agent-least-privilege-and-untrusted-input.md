# MEM: Agent least privilege and untrusted input
Date: 2026-10-21
Status: Approved
Tags: [security, prompt-injection, permissions]

## Summary
Every agent job gets the minimum token permissions and tool allowlist for its stage, and all
ticket/PR text is treated as untrusted data.

## Details
### Context & Evolution
See [ADR-0004](../../docs/adr/0004-agent-least-privilege-and-prompt-injection-stance.md).

### Specification
- Stage 1 and 3 agents are read-only (no `Edit`/`Write`, `contents: read`).
- Stage 2 gets enumerated `git` subcommands, `gh pr create`, and the project's test commands
  (`AI_TEST_TOOLS`). No force push (denied in `.claude/settings.json`), no merge, no `gh api`.
- Never expand `github.event.*.title|body|comment.body|head.ref` into `run:` or `prompt:` text
  (`workflows_static.test.sh` enforces). Pass numbers; the agent reads text through `gh`.
- In CI the agent cannot edit `.github/`, `.claude/`, `CLAUDE.md`, `tools/prompts/`,
  `tools/scripts/` (`.claude/hooks/protect-paths.sh`).
- `block-secrets.sh` rejects writes that contain credential literals.
- Notification scripts are checked out from the base branch when running in PR context.

## When to Use
When adding tools to an `--allowedTools` list, adding a workflow, or touching a prompt.
