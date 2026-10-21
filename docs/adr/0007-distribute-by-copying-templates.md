# ADR-0007: Distribute by copying templates

- Date: 2026-10-21
- Status: Accepted
- Related: [DESIGN.md](../architecture/DESIGN.md) section 13.4

## Context

The pipeline must be adopted by several product repositories, each with its own build, test and
deployment commands.

## Options considered

1. `install-into.sh` copies templates into each repository.
2. Reusable workflows hosted in one central repository, called by thin workflows.
3. A GitHub template repository.

## Decision

Option 1, never overwriting existing files unless `--force` is given.

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Copy | Each repo is self-contained and reviewable; local customisation is easy; no cross-repo coupling | Upgrades are manual; copies can drift |
| 2 Reusable workflows | One place to fix; instant propagation | A change in the central repo changes every repo at once, including its security posture; more complex permissions |
| 3 Template repo | Familiar | Only helps new repositories |

Reason: for 10–20 people the number of repositories is small and each is security-sensitive,
so explicit per-repo review of pipeline changes is a feature.

## Consequences

- Upgrade by running `install-into.sh --dry-run` and merging the differences.
- `CLAUDE.md` is never overwritten; `CLAUDE.pipeline.md` is written for manual merge.
- Revisit option 2 if the number of repositories grows beyond what can be updated by hand.
