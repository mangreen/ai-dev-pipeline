# 客製化指南

大多數客製化不需要改 workflow YAML，只要改 repository **variables**、`CLAUDE.md` 和
`tools/prompts/`。

## 1. 告訴 AI 如何建置與測試（最重要）

在 GitHub：`Settings` → `Secrets and variables` → `Actions` → `Variables`。

| Variable | 用途 | 範例 |
| --- | --- | --- |
| `AI_SETUP_CMD` | 實作階段開始前安裝依賴 | 見下表 |
| `AI_TEST_TOOLS` | 允許 Agent 執行的測試與 lint 指令（逗號分隔的工具白名單） | 見下表 |

| 語言 | `AI_SETUP_CMD` | `AI_TEST_TOOLS` |
| --- | --- | --- |
| Node | `npm ci` | `Bash(npm test:*),Bash(npm run lint:*)` |
| Python | `pip install -r requirements.txt` | `Bash(pytest:*),Bash(ruff check:*)` |
| Go | `go mod download` | `Bash(go test:*),Bash(go vet:*)` |
| Java (Maven) | `mvn -B -q dependency:resolve` | `Bash(mvn test:*),Bash(mvn -q verify:*)` |

注意：
- 白名單格式是 `Bash(指令前綴:*)`。只列出真正需要的指令，越窄越安全。
- 指令要能在 GitHub 提供的 `ubuntu-latest` 上執行；需要特定版本的語言環境時，請在
  `ai-implement.yml` 的 `Project setup` 步驟前加入對應的 `actions/setup-*` 步驟。
- 同樣的指令也要寫進 `CLAUDE.md` 的「Commands」表，讓 Agent 知道要用哪個。

## 2. 選擇模型

| Variable | 階段 | 預設 |
| --- | --- | --- |
| `AI_MODEL_PLAN` | 計畫 | `claude-opus-5-5` |
| `AI_MODEL_IMPLEMENT` | 實作 | `claude-sonnet-5-5` |
| `AI_MODEL_REVIEW` | 審查 | `claude-opus-5-5` |

模型 ID 請對照官方模型文件，帳號可用的模型可能不同。計畫與審查用較強的模型，實作用較快的模型，是
成本與品質的常見折衷；請依試行數據調整。

## 3. 調整提示詞

編輯 `tools/prompts/plan.md`、`implement.md`、`review.md`。它們是系統行為的一部分，修改請走 PR 並由
Code Owners 審查。在 CI 中 Agent 自己不能改這些檔案。

修改時保持：
- 只接收編號，文字由 `gh` 讀取（防 prompt injection）。
- 標題固定（`## AI Plan`、`## AI 需求釐清`），實作階段與通知邏輯依賴它們。
- 若改了狀態標籤，同步改 `setup-labels.sh`、workflow 的 `if:`、`docs/diagrams/pipeline-state.md`。

## 4. 通知對象

編輯 `.github/notify-owners.json`：`users` 放每個人的 GitHub 帳號、Slack 成員 ID、Teams 信箱；
`groups.default` 是找不到負責人時的備援，`groups.deploy` 是正式環境核准者。步驟見
[slack-teams-setup.md](slack-teams-setup.md)。

## 5. 部署

1. 把 `deploy.yml` 中兩個 `TODO(setup)` 的 `echo` 換成你的部署指令。
2. 建立 `staging`、`production` 兩個 Environment，並在 `production` 設定 Required reviewers。
3. 設定 variable `DEPLOY_ENABLED=true`。

## 6. 與既有 CI 並存

本 pipeline 不包含你專案的 CI。請讓你的 CI 在 PR 上執行，並把它列為分支保護的 required check。
AI 開的 PR 是由 Claude GitHub App 建立，所以會像一般 PR 一樣觸發 CI（見 DESIGN.md V1 的驗證項目）。

## 7. 把審查換成 Codex（交叉審查）

用 `openai/codex-action` 在第二個 job 執行審查並用 `actions/github-script` 貼留言，範例見
[官方 README](https://github.com/openai/codex-action)。保留 `ai-review.yml` 的 `notify` job。
Codex 的 API Key 另存為 `OPENAI_API_KEY` secret。
