# todo.md — active backlog

`[ ]` pending, `[x]` done. Only the current phase is listed in detail.

## Phase 0 — scaffold (v0.1.0)

- [x] Owner-aware notification script (Slack and Teams) with tests
- [x] Secret scanner, Claude Code hooks (block secrets, protect pipeline files) with tests
- [x] MEM bidirectional-link checker, doc link checker, label setup, installer with tests
- [x] Workflow templates: plan, implement, review, claude, deploy
- [x] Stage prompts, product rules, `CLAUDE.product.md`, skeleton, issue/PR templates
- [x] Design document, 7 ADRs, diagrams, API contract, guides, research summary
- [x] README with step-by-step installation
- [ ] Human: create the remote repository and push

## Phase 1 — validate in a real sandbox (blocks any wider rollout)

Each item maps to a verification item in `docs/architecture/DESIGN.md` section 14.

- [ ] V1 AI-authored PR triggers the project's CI and the AI review
- [ ] V2 Agent can use `gh` and `git push` in automation mode without extra credentials
- [ ] V3 `.claude/settings.json` hooks are active inside the Action (try editing `.github/`)
- [ ] V4 Teams Workflows webhook keeps `msteams.entities` mentions
- [ ] V5 Default model IDs exist in the team's account
- [ ] V6 Branch rulesets and environment reviewers are available on the team's GitHub plan
- [ ] Record results in DESIGN.md and add an ERR file for every surprise

## Phase 2 — trial (2 weeks, 3–5 low-risk tickets)

- [ ] Measure plan adoption rate, first-pass PR rate, cost per ticket
- [ ] Tune prompts and `--max-turns`; update ADRs if a decision changes (mark both sides)

## Later

- [ ] Cross-model review with `openai/codex-action` (ADR-0006)
- [ ] Weekly pipeline statistics report (`docs/reports/weekly/`)
- [ ] Pin third-party actions by commit SHA for high-security repositories
- [ ] Optional bridge for Linear (Cyrus) and Jira (`repository_dispatch`)
- [ ] Per-repository webhook/channel routing in `notify-owners.json`
- [ ] Idempotent notifications on workflow re-run
- [ ] `make diagrams-check`: render every Mermaid block in CI (done by hand for v0.1.0 with mermaid-cli)
