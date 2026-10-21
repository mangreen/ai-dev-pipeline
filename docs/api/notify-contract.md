# Notification contract (`tools/scripts/notify.sh`)

The only programmatic interface of this toolkit. Workflows call it; you can also call it from
your own scripts. Design rationale: [ADR-0003](../adr/0003-notifications-via-webhook-script.md).

## Input (environment variables)

| Variable | Required | Description |
| --- | --- | --- |
| `TITLE` | yes | One-line headline. Plain text. |
| `URL` | yes | Where the human should go (issue, PR, run). |
| `TEXT` | no | Body text (what is expected from the human). |
| `OWNERS` | no | Space-separated GitHub logins and/or `group:<name>`. Default `group:default`. |
| `MAP_FILE` | no | Owner map path. Default `.github/notify-owners.json`. |
| `SLACK_WEBHOOK_URL` | no | Slack incoming webhook. Platform skipped when empty. |
| `TEAMS_WEBHOOK_URL` | no | Teams Workflows webhook. Platform skipped when empty. |
| `NOTIFY_DRY_RUN` | no | `1` prints `{"platform":..., "payload":...}` lines instead of sending. |

`GITHUB_RUN_ID` and `GITHUB_ACTOR` are used for log fields; both default to `local`.

## Owner map (`.github/notify-owners.json`)

```json
{
  "users": {
    "octocat": { "name": "Octo Cat", "slack": "U0123456789", "email": "octo@example.com" }
  },
  "groups": { "default": ["octocat"], "deploy": ["octocat"] }
}
```

Resolution rules:

1. Each token of `OWNERS` is a login, or `group:<name>` expanded to its members.
2. Duplicates are removed; unknown logins are ignored.
3. If nobody remains, the members of `group:default` are used (a message always has an owner).
4. A user without `slack` gets no Slack mention; a user without `email` gets no Teams mention.

## Output and exit codes

| Condition | Result |
| --- | --- |
| Success | exit 0; JSON log line on stderr |
| Webhook returns non-2xx or is unreachable | exit 0; `::warning::<platform> notification failed (HTTP <code>)` |
| `TITLE` or `URL` missing | exit non-zero |
| No webhook configured | exit 0; warning log |

Log line shape (stderr): `{"ts":"2026-10-21T04:00:00Z","level":"info","msg":"sent platform=slack","trace_id":"<run id>","user_id":"<actor>"}`.
The webhook URL is never printed.

## Payloads

Slack (`text` only, mrkdwn; `& < >` in `TITLE`/`TEXT` are escaped):

```json
{ "text": "<@U0123456789> :raised_hand: *AI 計畫待審核：#7 ...*\n請審閱計畫 ...\n<https://github.com/o/r/issues/7|Open>" }
```

Teams (Adaptive Card 1.4 wrapped in a `message`):

```json
{
  "type": "message",
  "attachments": [{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
      "type": "AdaptiveCard",
      "version": "1.4",
      "body": [
        { "type": "TextBlock", "wrap": true, "text": "<at>Octo Cat</at>" },
        { "type": "TextBlock", "weight": "Bolder", "wrap": true, "text": "TITLE" },
        { "type": "TextBlock", "wrap": true, "text": "TEXT" }
      ],
      "actions": [{ "type": "Action.OpenUrl", "title": "Open", "url": "URL" }],
      "msteams": { "entities": [{ "type": "mention", "text": "<at>Octo Cat</at>",
                                   "mentioned": { "id": "octo@example.com", "name": "Octo Cat" } }] }
    }
  }]
}
```

NOTE: whether a Workflows webhook keeps `msteams.entities` mentions must be verified in your
tenant (verification item V4 in [DESIGN.md](../architecture/DESIGN.md)).

## Events sent by the workflow templates

| Event | Workflow / job | Owner | Wording keyword |
| --- | --- | --- | --- |
| Plan ready | `ai-plan` / `notify` | assignee, else author | 計畫待審核 |
| AI needs answers | `ai-plan` / `notify` | assignee, else author | 釐清需求 |
| Plan stage failed | `ai-plan` / `notify` | assignee, else author | 計畫階段失敗 |
| Implementation failed | `ai-implement` / `notify` | assignee, else author | 實作失敗 |
| No PR was opened | `ai-implement` / `notify` | assignee, else author | 沒有開 PR |
| AI PR ready for human review | `ai-review` / `notify` | owner of the `Closes #N` issue | 待人工審查與合併 |
| AI review failed | `ai-review` / `notify` | owner of the `Closes #N` issue | AI 審查失敗 |
| Production awaits approval | `deploy` / `notify-approval` | `group:deploy` | 正式環境等待核准 |
| Deployment failed or rejected | `deploy` / `notify-failure` | `group:deploy` | 部署失敗 |

The keywords are asserted by `tests/integration/workflow_notify_steps.test.sh`; change wording
and tests together.
