# Engineering standard: how it is applied to this project

The team's "AI Loop/Graph Engineering — System Prompt v3.0" is the engineering standard. It was
written for application development (API, database, layered `src/`). This repository is a
toolkit made of shell scripts, GitHub workflow templates and documents, so each section is
applied, adapted, or marked not applicable, with the reason. The rules for product repositories
that install the pipeline are the unadapted application rules, shipped in
`templates/CLAUDE.product.md` and `templates/rules/`.

## Section by section

| § | Topic | Here | How |
| --- | --- | --- | --- |
| 1 | Role and mindset | Applied | [CLAUDE.md](../../CLAUDE.md); impact analysis before changes; smallest milestones |
| 2 | Principles (Clean/Hexagonal, SOLID, DDD) | Adapted | No application layers. Equivalent structure: ports and adapters appear as the stable environment-variable interface of `notify.sh` and the fake `gh`/mock webhook in tests. Applied in full in the product template |
| 2 | KISS, readability, CI-friendly | Applied | One script per job, `make check`, CI runs the same targets |
| 2 | Trade-off Analysis block | Applied | In every ADR and in [DESIGN.md](../architecture/DESIGN.md) §13 |
| 3 | Test pyramid | Adapted | `tests/unit` (pure, dry-run, no network) and `tests/integration` (local mock webhook, fake `gh`, temporary git repos). No E2E against a real GitHub organization by default; that is the smoke test in the README |
| 3.2 | AAA, naming `should_..._when_...`, mutation mindset | Applied | Test names and structure follow it |
| 3.2 | Concurrency testing | Not applicable | The scripts hold no shared state. Workflow-level serialization is a static test (`concurrency` group per issue) |
| 3.3 | 80% coverage gate | Replaced | Line coverage of bash is not meaningful here. The gate is the scenario matrix: every notification event, every owner-resolution rule and every guard-rail has a named test; CI fails on any red test |
| 4.1 | Input validation (DTO, whitelist) | Adapted | `notify.sh` validates required inputs, and untrusted text is escaped. Workflow templates never expand untrusted event text |
| 4.1 | Idempotency-Key | Not applicable | No HTTP API. Known limitation: re-running a workflow re-sends its notification |
| 4.1 | Dependency scanning | Adapted | Dependabot for GitHub Actions versions; no language packages |
| 4.2 | Structured logging, trace-id | Applied | `notify.sh` logs JSON with `trace_id` (GitHub run id) and `user_id` (actor) |
| 4.2 | Global exception filter | Adapted | Notification failures are caught and turned into a warning; never a stack trace, never a failed pipeline |
| 4.3 | Secrets management | Applied | `.env.example`, `.gitignore`, `scan-secrets.sh`, hooks, Gitleaks in CI, placeholder policy |
| 5 | Graph / impact analysis | Applied | [component-graph.md](../diagrams/component-graph.md) with a checklist |
| 6 | TDD loop, phases | Applied | New code is test-first (for example `check-doc-links.sh` was written Red, then Green, and a flaky hook test was reproduced before it was fixed); no phased flow needed |
| 7.1 | Context compression | Not applicable here | A session-level behaviour of the agent, not a repository artifact |
| 7.2 | MEM / ERR / SKILL, todo.md, bidirectional links | Applied | `.agents/` and `todo.md`; links enforced by `check-memory-links.sh` |
| 8 | GitHub Flow, Conventional Commits | Applied | Also installed into products as `.claude/rules/git-and-commits.md` |
| 9 | Daily / weekly / monthly reports | Deferred | Directory kept; no report content is generated for a toolkit with no daily activity. Possible future: a scheduled weekly report of pipeline statistics |
| 10 | Project structure | Adapted | `src/` layers replaced by `templates/` and `tools/`; `docs/` follows the standard; `.agents/` and `.claude/` as specified |
| 11 | Comment standard | Applied | English comments, why-not-what, `FIXME`/`TODO`/`NOTE` |
| 12 | Trigger matrix | Applied | Reflected in [CLAUDE.md](../../CLAUDE.md) |
| 13–14 | Must-do list, execution principles | Applied | CLAUDE.md "never negotiable" rules |

## Inconsistencies found in the standard (decisions taken)

1. §7.2 names the memory folders `./memory/`, `./error/` and `./skill/`, while §10 names
   `.agents/memories`, `.agents/errors` and `.agents/skills`. This project follows §10.
2. §6 says "phase by phase (see Section 11)", but §11 is the comment standard; no phase list is
   defined. This project uses GitHub Flow and a backlog in [todo.md](../../todo.md).
3. §8 offers GitHub Flow or Phase Flow. GitHub Flow was chosen because the toolkit is released
   as versions (`v0.x`), not studied in phases.
4. §4.3's pattern `sk-[a-zA-Z0-9]` produces false positives on ordinary words; refined with a
   test ([ERR-20261021](../../.agents/errors/ERR-20261021-sk-regex-matches-risk-based.md)).
5. The end of the source document contains stray text (a closing quote and Python file-writing
   lines) left over from the way it was exported; ignored.
6. ADR (`docs/adr/`) and MEM (`.agents/memories/`) overlap. Convention used: the ADR holds the
   full reasoning and options; the MEM is the short, authoritative rule an agent obeys, and each
   MEM links to its ADR.
