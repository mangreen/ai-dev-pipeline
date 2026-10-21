# 維運手冊（Runbook）

所有問題先看：repo 的 `Actions` 分頁 → 點最新的 run → 點紅色叉叉的 job 與步驟 → 讀錯誤訊息。

## 症狀與處理

| 症狀 | 可能原因 | 處理 |
| --- | --- | --- |
| 貼了標籤但沒有任何 run | workflow 不在預設分支；Actions 被停用；標籤名稱不一致 | 確認 `.github/workflows/` 在 `main`；`Settings` → `Actions` 啟用；標籤須與 `setup-labels.sh` 建立的一致 |
| run 出現「skipped」 | 貼了其他標籤，job 的 `if:` 不符 | 正常 |
| 認證錯誤（401） | `ANTHROPIC_API_KEY` 名稱錯、無效、無額度；Claude GitHub App 沒裝到此 repo | 重設 secret；安裝 App；先在本機用同一把 Key 測試 |
| 「沒有權限」或被拒絕 | 觸發者沒有寫入權限 | 設計如此；請有權限的人操作 |
| 貼不上 `needs:*` 標籤 | 標籤不存在 | `bash tools/scripts/setup-labels.sh --repo owner/name` |
| AI 開了 PR 但 CI／AI 審查沒跑 | PR 以 `GITHUB_TOKEN` 建立（不觸發 workflow） | 不要給 action 傳 `github_token: ${{ secrets.GITHUB_TOKEN }}`；仍不行就用 `actions/create-github-app-token`（見 ERR 記錄） |
| AI 說測試指令不能執行 | `AI_TEST_TOOLS` 沒包含該指令 | 更新 repository variable |
| 測試因缺少依賴失敗 | 沒設 `AI_SETUP_CMD`，或需要特定工具版本 | 設定 variable，或在 workflow 加 `actions/setup-*` |
| 沒收到通知 | secret 未設；webhook 失效；擁有者對照表缺人 | 看 run 日誌中的 `::warning::`；本機用 `NOTIFY_DRY_RUN=1` 檢查 payload（見 [slack-teams-setup.md](slack-teams-setup.md)） |
| 通知有送但沒有 @mention | 對照表沒有 Slack ID／信箱；Teams 的 Workflows 不保留提及 | 補資料；見 DESIGN.md V4 |
| Agent 想改 `.github/` 被擋 | `protect-paths` hook 生效（預期） | 把需要的修改寫在 PR 內文，由人修改 |
| 費用異常 | 迴圈、ticket 過大、PR 頻繁更新 | 看 Anthropic Console 的用量；調低 `--max-turns`；拆分 ticket；停用 workflow |
| `gitleaks` job 失敗並提到授權 | 組織帳號需要 Gitleaks 授權金鑰 | 依官方說明取得，存為 `GITLEAKS_LICENSE` secret |

## 緊急停止

1. `Actions` 分頁左側選該 workflow → `⋯` → `Disable workflow`（逐一停用 `AI Plan`、`AI Implement`、
   `AI Review`、`Claude Code`）。
2. 到 Anthropic Console 停用 pipeline 專用的 API Key。
3. 檢查近期的 PR 與 commit 是否有不該存在的變更。

## 輪替機密

| 機密 | 做法 |
| --- | --- |
| API Key | Console 建新 Key → 更新 `ANTHROPIC_API_KEY` → 停用舊 Key |
| Webhook URL | 在 Slack／Teams 重新產生 → 更新 secret → 刪除舊的 |

## 離職與新人

- 更新 `.github/notify-owners.json`（走 PR）。
- 檢查 CODEOWNERS、Environment 的 Required reviewers、repo 權限。
