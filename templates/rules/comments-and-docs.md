# Comments and documentation rules

## Comments

- Explain why, not what. Keep them to one or two lines. Do not comment every line.
- Use one language consistently (the team's agreed language for code comments).
- Markers: `// FIXME:` temporary logic to replace, `// TODO:` work to do, `// NOTE:` a
  non-obvious reason or constraint.
- Update the comment when the code changes. Delete comments that became false.
- Never leave realistic-looking fake secrets; use obvious placeholders with a FIXME.

## Documentation

- Whenever a design or interface changes, update the matching diagram or document in `docs/`.
- Diagrams are Mermaid (`graph TD`, `flowchart LR`, `sequenceDiagram`, `erDiagram`).
- Significant architectural decisions get an ADR in `docs/adr/` and a `MEM-*.md` in
  `.agents/memories/`.
- Keep `README.md` accurate: setup, architecture, trade-offs, how to run tests.
- Before changing code, do an impact analysis: controller → use case → repository upstream,
  DTO → API contract (OpenAPI) downstream.
