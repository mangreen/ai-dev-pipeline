# ADR-0003: Notifications through a webhook script

- Date: 2026-10-21
- Status: Accepted
- Related: [MEM-0004](../../.agents/memories/MEM-0004-notifications-via-webhook-script.md), [notify-contract.md](../api/notify-contract.md)

## Context

When a human is needed the team must be told in Slack or Teams, with the owner mentioned.
Some teams use Slack, some Teams, some both.

## Options considered

1. The official GitHub apps for Slack and Teams (subscriptions).
2. A Slack app / Teams bot with its own hosting.
3. One bash script posting to incoming webhooks, with an owner map.

## Decision

Option 3. Teams uses a Workflows webhook (the legacy Office 365 connectors were scheduled for
retirement in 2026).

## [Trade-off Analysis]

| Option | Pros | Cons |
| --- | --- | --- |
| 1 Official apps | No code | Generic event feed; no per-issue owner mention logic; cannot express "AI needs your decision" |
| 2 Own app/bot | Rich interaction (buttons, DMs) | Hosting, OAuth, review burden |
| 3 Webhook script | No hosting; same code for both platforms; testable offline; mention by assignee | One channel per webhook; Teams mention support must be verified (V4); no interactivity |

Reason: the requirement is one-way "tap on the shoulder"; interaction happens on GitHub.

## Consequences

- Notifications never fail the pipeline; a warning annotation is emitted instead.
- External text is escaped for Slack; the webhook URL is never logged.
- Upgrading to a bot later means replacing `notify.sh`; the call sites keep the same
  environment-variable interface.
