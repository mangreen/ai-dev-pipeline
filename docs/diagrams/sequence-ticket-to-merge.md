# Diagram: from ticket to merged pull request

```mermaid
sequenceDiagram
    autonumber
    actor Owner as 負責人（人）
    participant GH as GitHub (issue / PR / labels)
    participant Plan as ai-plan.yml
    participant Impl as ai-implement.yml
    participant Rev as ai-review.yml
    participant AI as Claude Code (claude-code-action)
    participant N as notify.sh
    participant Chat as Slack / Teams

    Owner->>GH: 建立 issue、指派自己、貼 ai:plan
    GH->>Plan: issues.labeled(ai:plan)
    Plan->>AI: prompt = tools/prompts/plan.md + issue 編號
    AI->>GH: gh issue view（讀取不可信的 issue 文字）
    AI->>GH: 留言「AI Plan」、貼 needs:plan-approval、移除 ai:plan
    Plan->>N: notify job（讀取標籤判斷狀態）
    N->>Chat: @負責人 計畫待審核
    Owner->>GH: 審閱計畫、必要時留言修正
    Owner->>GH: 貼 plan-approved（關卡 1）
    GH->>Impl: issues.labeled(plan-approved)
    Impl->>AI: prompt = tools/prompts/implement.md + issue 編號
    AI->>GH: 建分支、TDD、commit、gh pr create（Closes #N）
    GH->>Rev: pull_request.opened（作者為 Bot）
    Rev->>AI: prompt = tools/prompts/review.md + PR 編號
    AI->>GH: inline comment + 摘要留言（不核准、不合併）
    Rev->>N: notify job（腳本從 base 分支取出）
    N->>Chat: @負責人 PR 待人工審查與合併
    Owner->>GH: 審查程式碼、核准、合併（關卡 2，由分支保護強制）
```

Failure paths: if `plan` or `implement` fails, their `notify` job still runs (`if: always()`)
and sends a failure message with the run link. A successful implementation stays silent because
the review workflow announces the PR.
