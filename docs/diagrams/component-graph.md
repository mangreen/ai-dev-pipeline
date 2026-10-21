# Diagram: component dependency graph (impact analysis)

Use this before changing anything: an arrow `A --> B` means "A depends on B", so a change to B
may break A (upstream impact) and a change to A may need B to be updated (downstream).

```mermaid
graph TD
    INST[install-into.sh] --> TW[templates/workflows/*.yml]
    INST --> TG[templates/github/*]
    INST --> TR[templates/rules/*]
    INST --> TS[templates/skeleton/*]
    INST --> TC[templates/CLAUDE.product.md]
    INST --> SC[tools/scripts/*]
    INST --> PR[tools/prompts/*]
    INST --> CL[.claude/settings.json, hooks, skills]

    TW -->|run: bash tools/scripts/notify.sh| NOTIFY[notify.sh]
    TW -->|prompt: read file| PR
    TW -->|labels| LAB[setup-labels.sh]
    NOTIFY --> MAP[.github/notify-owners.json]
    CL --> BS[hooks/block-secrets.sh]
    CL --> PP[hooks/protect-paths.sh]
    BS --> SCAN[scan-secrets.sh]
    TS --> MEM[check-memory-links.sh]

    T1[tests/unit/*] --> SC
    T2[tests/integration/workflows_static] --> TW
    T3[tests/integration/workflow_notify_steps] --> TW
    T3 --> NOTIFY
    T4[tests/unit/install_into] --> INST
    CI[.github/workflows/ci.yml] --> T1
    CI --> T2
```

## Impact checklist

| If you change | Also check |
| --- | --- |
| A label name | `setup-labels.sh` + test, workflow `if:` conditions, prompts, `pipeline-state.md`, README |
| `notify.sh` interface | every `notify` job, [notify-contract.md](../api/notify-contract.md), tests |
| A workflow template | `workflows_static`, `workflow_notify_steps`, `install_into` tests; DESIGN.md |
| A prompt | the workflow that names it, `protect-paths.sh` (it is protected in CI), review prompt consistency |
| `.claude/settings.json` | installer copies it to product repos; hooks tests |
