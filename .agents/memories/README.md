# Memories (MEM) — architecture and decisions

Long-term knowledge of this repository. One decision per file: `MEM-<seq>-<topic>.md`
(four-digit sequence, lowercase topic). Longer reasoning lives in the linked ADR under
`docs/adr/`; a MEM is the short, authoritative statement an AI agent should obey.

Rules, template and the bidirectional-linking requirement:
[templates/skeleton/.agents/memories/README.md](../../templates/skeleton/.agents/memories/README.md).
`tools/scripts/check-memory-links.sh` validates this directory in CI.

## Index

| MEM | Topic | Status | ADR |
| --- | --- | --- | --- |
| [MEM-0001](MEM-0001-label-driven-github-native-pipeline.md) | Label-driven, GitHub-native pipeline | Approved | [ADR-0001](../../docs/adr/0001-github-native-label-driven-pipeline.md) |
| [MEM-0002](MEM-0002-three-human-gates.md) | Three human gates enforced by the platform | Approved | [ADR-0002](../../docs/adr/0002-three-human-gates-enforced-by-github.md) |
| [MEM-0003](MEM-0003-agent-least-privilege-and-untrusted-input.md) | Agent least privilege and untrusted input | Approved | [ADR-0004](../../docs/adr/0004-agent-least-privilege-and-prompt-injection-stance.md) |
| [MEM-0004](MEM-0004-notifications-via-webhook-script.md) | Notifications via a webhook script | Approved | [ADR-0003](../../docs/adr/0003-notifications-via-webhook-script.md) |
