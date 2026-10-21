# Diagram: human gates and deployment

```mermaid
flowchart LR
    subgraph AI[AI 階段（可自動）]
        P[計畫<br/>ai-plan.yml]
        I[實作<br/>ai-implement.yml]
        R[審查<br/>ai-review.yml]
    end
    subgraph DET[確定性 CI/CD（無 AI）]
        CI[專案 CI<br/>測試 / lint / 掃描]
        S[部署 staging]
        D[部署 production]
    end
    G1{{關卡 1<br/>人貼 plan-approved}}
    G2{{關卡 2<br/>人核准並合併<br/>分支保護 + CODEOWNERS}}
    G3{{關卡 3<br/>Environment 審核者}}
    N[(notify.sh<br/>Slack / Teams)]

    P --> G1 --> I --> R --> G2
    CI -. required check .-> G2
    G2 --> S --> G3 --> D
    P -. 通知 .-> N
    R -. 通知 .-> N
    S -. 通知 .-> N
    I -. 失敗時通知 .-> N
```

The three diamonds are the only places where the pipeline waits for a person. They are enforced
by GitHub features (label permissions, rulesets, environment reviewers), so an agent that
misbehaves cannot skip them. See
[MEM-0002](../../.agents/memories/MEM-0002-three-human-gates.md).
