# Diagram: ticket state machine

Source of truth for label semantics (see
[MEM-0001](../../.agents/memories/MEM-0001-label-driven-github-native-pipeline.md)). Update this
file whenever a label, trigger or gate changes.

```mermaid
stateDiagram-v2
    [*] --> Open: 人建立 issue（ai-task 範本）並指派負責人
    Open --> Planning: 人貼 ai:plan
    Planning --> NeedsClarification: AI 有疑問（needs:clarification）
    NeedsClarification --> Planning: 人回覆後重貼 ai:plan
    Planning --> NeedsPlanApproval: AI 產出計畫（needs:plan-approval）
    NeedsPlanApproval --> Planning: 人要求重做，重貼 ai:plan
    NeedsPlanApproval --> Implementing: 關卡 1，人貼 plan-approved
    Implementing --> PrOpen: AI 開 PR
    Implementing --> Blocked: 失敗或沒開 PR，通知負責人
    Blocked --> Implementing: 人調整後重貼 plan-approved
    PrOpen --> InReview: AI 審查完成，通知負責人
    InReview --> PrOpen: 人用 @claude 要求修改
    InReview --> Merged: 關卡 2，人核准並合併
    Merged --> Staging: push main，自動部署
    Staging --> AwaitProduction: 通知 deploy 群組
    AwaitProduction --> Production: 關卡 3，人核准部署
    AwaitProduction --> [*]: 人拒絕
    Production --> [*]
```

## Label reference

| Label | Set by | Meaning | Removed by |
| --- | --- | --- | --- |
| `ai:plan` | Human | Start (or restart) stage 1 | The plan agent consumes it when done |
| `needs:clarification` | Plan agent | Questions waiting for the human | Plan agent at the next round |
| `needs:plan-approval` | Plan agent | Plan is ready for gate 1 | Plan agent at the next round |
| `plan-approved` | Human | Gate 1 passed: implement | Human removes it to re-run stage 2 (remove, then add again) |

A workflow starts only when a label is *added*. To re-run a stage, remove the label and add it
again.
