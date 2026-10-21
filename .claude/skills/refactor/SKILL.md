---
name: refactor
description: Refactor safely under test. Use when asked to clean up, deduplicate or restructure code without changing behaviour.
---

# Refactor

1. Confirm the behaviour is covered by tests. If not, write characterization tests first and
   watch them pass on the unchanged code.
2. Do an impact analysis: which callers and which documents depend on what you will touch.
3. Change one thing at a time. Run the full test suite (command listed in `CLAUDE.md`) after
   each step.
4. Remove duplication, rename for clarity, delete dead code and temporary fakes
   (`FIXME: Replace with real logic`). Keep comments explaining why, not what.
5. Never edit a test to make a refactor pass. A failing test means behaviour changed.
6. Commit each step as `refactor(<scope>): <subject>`.
