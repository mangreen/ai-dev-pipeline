# Git and commit rules (GitHub Flow)

- `main` is always stable and testable. Never push to it; merge only through a reviewed PR with
  passing checks.
- Branch from `main`, keep branches short-lived: `feature/*`, `fix/*`, `refactor/*`, `test/*`,
  `chore/*`. AI branches use `claude/issue-<N>-<slug>`.
- Delete the branch after merge. Releases are tags (`v0.1.0`, `v1.0.0`). No `develop`, no
  `release/*` branches.
- One commit = one complete, testable unit. Use Conventional Commits:

```text
<type>(<scope>): <subject>

<body - what and why>

<footer - issue reference, breaking changes>
```

- Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
- Update `CHANGELOG.md` when a feature is completed.
