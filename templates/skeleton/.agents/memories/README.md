# Memories (MEM) — architecture and decisions

Long-term knowledge that must survive between sessions. One decision per file:
`MEM-<seq>-<topic>.md` (`seq` is four digits: 0001, 0002, ...; topic is lowercase-with-dashes).

Do not create scattered `memory.md`, `summary.md` or `next-step.md` files.

## Bidirectional linking (mandatory)

When a new MEM changes or replaces an old one, mark BOTH files. Editing one side only is a
defect. If the old document can simply be edited in place, edit it instead of creating a new one
and keep the history in "Context & Evolution".

| File | Status line | Summary must contain |
| --- | --- | --- |
| Old | `Status: Superseded by MEM-0007-new.md` | `DEPRECATED: Superseded by [MEM-0007-new.md](MEM-0007-new.md)` |
| New | `Status: Supersedes MEM-0003-old.md` | `Updates/Supersedes [MEM-0003-old.md](MEM-0003-old.md)` |

`tools/scripts/check-memory-links.sh` verifies this and runs in CI. An AI agent must IGNORE a
specification whose status is Superseded.

## Template

```markdown
# MEM: <Topic>
Date: YYYY-MM-DD
Status: Approved
Tags: [tag1, tag2]

## Summary
(One sentence.)

## Details
### Context & Evolution
(Background of this choice and how it changed.)

### Specification
...

## When to Use
(Under which circumstances to refer to this.)
```
