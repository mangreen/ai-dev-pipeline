# Slack 與 Teams 通知設定

通知用 webhook 發送，Slack 與 Teams 可以同時使用，也可以只用其中一個。沒設定的平台會被自動略過。
腳本介面與訊息格式：[notify-contract.md](../api/notify-contract.md)。

## A. Slack

### 1. 建立 Incoming Webhook

1. 打開 [api.slack.com/apps](https://api.slack.com/apps)，按 `Create New App` → `From scratch`，命名並選擇你的工作區。
2. 左側選 `Incoming Webhooks`，把開關打開。
3. 按 `Add New Webhook to Workspace`，選擇要接收通知的頻道，按 `Allow`。
4. 複製產生的 Webhook URL。**這個 URL 等同密碼**：拿到的人可以在該頻道發訊息。
5. 一個 webhook 只對應一個頻道。不同 repo 要發到不同頻道，就各建一個 webhook。

### 2. 查每個人的 Slack 成員 ID（用於 @mention）

點成員頭像 → `View full profile` → 右上角 `⋮` → `Copy member ID`。格式像 `U0123456789`。

### 3. 存成 secret

repo 的 `Settings` → `Secrets and variables` → `Actions` → `New repository secret`，
名稱 `SLACK_WEBHOOK_URL`，值貼上 URL。

## B. Microsoft Teams

舊的「Office 365 連接器」webhook 已在 2026 年停用，請使用 **Workflows**。

### 1. 建立 Workflows webhook

1. 在目標頻道按 `…` → `Workflows`。
2. 選範本 `Send webhook alerts to a channel`，確認團隊與頻道後儲存。
3. 複製產生的 webhook 連結（同樣等同密碼）。
4. 目前私人頻道的支援可能不完整，請先使用標準頻道，並以微軟最新文件為準。

### 2. 存成 secret

名稱 `TEAMS_WEBHOOK_URL`。

### 3. @mention 的限制

腳本送出的 Adaptive Card 帶有 `msteams.entities` 提及資訊（以信箱識別人）。文件主要說明舊版
incoming webhook 支援，**Workflows webhook 是否保留提及需要在你的租戶驗證**（DESIGN.md 的 V4）。

驗證方法：
1. 先把你自己放進 `notify-owners.json` 的 `default` 群組。
2. 本機執行（見下節）送一則測試通知。
3. 確認你本人有收到被提及的通知。若只有文字沒有提及，通知仍會送達頻道，但需要改成在 Workflows
   流程內加一個步驟處理提及。

## C. 設定擁有者對照表

編輯 `.github/notify-owners.json`：

```json
{
  "users": {
    "alice-gh": { "name": "Alice Chen", "slack": "U0123456789", "email": "alice@your-company.example" }
  },
  "groups": { "default": ["alice-gh"], "deploy": ["alice-gh"] }
}
```

- `alice-gh` 是 GitHub 登入名稱（Assignee 欄位顯示的那個）。
- `email` 要是 Microsoft 365 登入信箱。
- 找不到對應的人時，通知會改發給 `default` 群組成員。

## D. 在本機測試

```bash
cp .env.example .env            # 填入 webhook；.env 已被 .gitignore
set -a; source .env; set +a
NOTIFY_DRY_RUN=1 TITLE="測試" URL="https://example.com" OWNERS="alice-gh" \
  bash tools/scripts/notify.sh   # 先看 payload，不實際送出
NOTIFY_DRY_RUN=0 TITLE="測試" URL="https://example.com" OWNERS="alice-gh" \
  bash tools/scripts/notify.sh   # 真的送出
```
