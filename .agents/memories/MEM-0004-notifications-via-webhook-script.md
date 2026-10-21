# MEM: Notifications via a webhook script
Date: 2026-10-21
Status: Approved
Tags: [notifications, slack, teams]

## Summary
Human-attention events are sent to Slack and/or Teams by one bash script that posts to
incoming webhooks and mentions owners resolved from a JSON map.

## Details
### Context & Evolution
See [ADR-0003](../../docs/adr/0003-notifications-via-webhook-script.md). Contract:
[docs/api/notify-contract.md](../../docs/api/notify-contract.md).

### Specification
- Script: `tools/scripts/notify.sh`; owner map: `.github/notify-owners.json`
  (GitHub login → Slack member ID, Teams email; groups `default` and `deploy`).
- Owner of an issue-level event = assignee, else issue author, else group `default`.
- Slack mentions use `<@MEMBER_ID>`; external text is escaped. Teams uses an Adaptive Card with
  `msteams.entities` (mention behaviour on Workflows webhooks must be verified per tenant).
- Notification failure must never fail the pipeline; it emits a `::warning::`.
- The webhook URL is a credential: never log it.

## When to Use
When adding an event that needs a human, changing message wording, or onboarding a channel.
