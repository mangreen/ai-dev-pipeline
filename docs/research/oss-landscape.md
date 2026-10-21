# Research: open-source options for a ticket-to-production AI pipeline

Collected 2026-10-21 from the project pages and documentation listed below. Facts were taken
from those pages; items marked "not verified" were not confirmed. Re-check before relying on
them: this field changes quickly.

## Executors that run in CI

| Project | Licence / status | Notes |
| --- | --- | --- |
| [anthropics/claude-code-action](https://code.claude.com/docs/en/github-actions) | Official GitHub Action (v1) | Interactive mode (`@claude`) and automation mode (`prompt`). Auth: API key, OAuth token, Bedrock/Vertex/Foundry via OIDC, workload identity federation. Docs recommend an API key for organisation-wide use |
| [openai/codex-action](https://github.com/openai/codex-action) | Official GitHub Action | Inputs include `permission-profile`, `safety-strategy`; designed to limit privileges; the README shows a PR-review workflow |

## Ticket-driven orchestrators

| Project | Licence | Trackers | Agents | Maturity notes |
| --- | --- | --- | --- | --- |
| [openai/symphony](https://github.com/openai/symphony) | Apache-2.0 | Linear (primary example) | Codex (`codex app-server`) | README: "low-key engineering preview for testing in trusted environments"; Elixir reference marked prototype / evaluation only; custom Linear states needed (Rework, Human Review, Merging) |
| Cyrus ([ceedaragents/cyrus](https://gitea.com/atcyrus/cyrus), [docs](https://www.atcyrus.com/docs/introduction.md)) | Apache-2.0 (per repository LICENSE file) | Linear, GitHub, GitLab, Slack | Claude Code, Codex, Cursor, Gemini | Self-hosted community mode and paid self-hosted/cloud plans; vendor page says about 3–5x more tokens than local use because of verification loops; the docs page does not state the licence |
| [langchain-ai/open-swe](https://github.com/langchain-ai/open-swe) | MIT | Slack, GitHub, Linear (via MCP) | Configurable models | README: under active development, breaking changes expected, not accepting external contributions; team deployment involves backend, dashboard and several apps |
| Agent Orchestrator (Untrivial-ai, formerly ComposioHQ) | Apache-2.0 | none named | 26 worker harnesses | npm CLI frozen at 0.10.0 per a third-party survey |
| Vibe Kanban ([BloopAI/vibe-kanban](https://github.com/BloopAI/vibe-kanban)) | Apache-2.0 | own board | 10+ | Vendor announced shutdown on 2026-04-10; community-maintained afterwards (per the survey) |
| Claude Squad, Emdash, Baton, Bernstein, others | various | mostly none or GitHub Issues | various | Mostly developer-desktop or single-maintainer tools; see the survey |

Survey used for the table above: [9 Open-Source Agent Orchestrators for AI Coding (2026)](https://www.augmentcode.com/tools/open-source-agent-orchestrators)
and [awesome-agent-orchestrators](https://github.com/andyrewlee/awesome-agent-orchestrators).

## Review and specification tools

| Project | Notes |
| --- | --- |
| [PR-Agent](https://www.qodo.ai/blog/qodo-is-handing-pr-agent-over-to-the-community/) | Qodo handed it to a community organisation (`The-PR-Agent`) and returned the licence to Apache-2.0; remains self-hostable |
| [GitHub Spec Kit](https://levelop.dev/blog/github-spec-kit-hands-on-guide) | Commands `/speckit.constitution`, `specify`, `plan`, `tasks`, `implement`; supports Claude Code, Codex, Copilot, Cursor, Gemini CLI (from a third-party guide) |

## Findings that shaped the design

1. There is no official "assign a Linear issue to Claude Code" feature; the request is open as a
   GitHub issue on the Claude Code repository, with Cyrus and bridges as workarounds.
2. The most prominent orchestrators describe themselves as previews or as changing fast.
3. Teams that already host code and CI on GitHub can get gates for free from rulesets and
   environments; hence [ADR-0001](../adr/0001-github-native-label-driven-pipeline.md).
4. Microsoft's Office 365 connectors for Teams were scheduled for retirement in 2026; Workflows
   webhooks replace them ([ADR-0003](../adr/0003-notifications-via-webhook-script.md)).
5. Events created with `GITHUB_TOKEN` do not trigger workflows (documented by the action).

## Not verified

- Whether the Cyrus community edition and the paid edition differ in licence terms beyond what
  the repository LICENSE says.
- Behaviour of `msteams.entities` mentions on Workflows webhooks (see DESIGN.md V4).
- Actual token cost of this pipeline in your codebase (measure during the trial).
