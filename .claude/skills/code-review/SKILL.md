---
name: code-review
description: Review a diff or pull request against the project's engineering standard (security, tests, plan adherence, docs). Use before marking work complete or when asked to review.
---

# Code review

1. Get the diff: `git diff main...HEAD` (or `gh pr diff <N>`).
2. Run the secret scan: `bash tools/scripts/scan-secrets.sh --base main`. Any finding is blocking.
3. Check in this order: correctness, security, tests, plan adherence, documentation, commits.
   Details and wording rules: `tools/prompts/review.md`.
4. Verify tests are meaningful: would they fail if a comparison operator were flipped? Do names
   follow `should_<behavior>_when_<condition>`?
5. If a design or interface changed, confirm the diagram, API doc and ADR/MEM were updated.
6. Report findings with file and line, the impact and a suggested fix. Separate blocking from
   non-blocking. State what you could not verify.
