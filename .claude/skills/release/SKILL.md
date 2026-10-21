---
name: release
description: Prepare a release - changelog, version, release notes. Use when asked to cut a release. Never tags or deploys by itself.
---

# Release

1. Make sure `main` is green in CI. Do not release from a feature branch.
2. Move the `## [Unreleased]` entries of `CHANGELOG.md` under a new `## [x.y.z] - YYYY-MM-DD`
   heading. Choose the version by Semantic Versioning.
3. Verify that `README.md` and the architecture documents still describe reality (setup steps,
   configuration, environment variables).
4. Commit as `chore(release): vX.Y.Z`, open a PR, wait for human approval and merge.
5. A human creates the tag `vX.Y.Z` on `main`. Agents never push tags to the default branch and
   never trigger a production deployment; that is human gate 3.
6. Draft release notes from the changelog: what changed, migration steps, known issues.
