#!/usr/bin/env bash
# Send a "human attention needed" message to Slack and/or Microsoft Teams and
# mention the owner(s).
#
# Input (environment variables):
#   TITLE, URL          required
#   TEXT                optional body text
#   OWNERS              space separated GitHub logins or `group:<name>` (default: group:default)
#   MAP_FILE            owner map, default .github/notify-owners.json
#   SLACK_WEBHOOK_URL   Slack incoming webhook (platform skipped when unset)
#   TEAMS_WEBHOOK_URL   Teams Workflows webhook (platform skipped when unset)
#   NOTIFY_DRY_RUN=1    print payloads to stdout instead of sending (used by tests)
#
# Exit codes: 0 even when a webhook call fails (notification must never fail the
# pipeline; a ::warning:: annotation is emitted instead), 1 on missing input.
set -uo pipefail

MAP_FILE="${MAP_FILE:-.github/notify-owners.json}"
: "${TITLE:?TITLE is required}" "${URL:?URL is required}"
TEXT="${TEXT:-}"
OWNERS="${OWNERS:-group:default}"

# Structured JSON log on stderr: timestamp, trace id (workflow run) and user id (actor).
log() {
  jq -nc --arg level "$1" --arg msg "$2" --arg trace "${GITHUB_RUN_ID:-local}" --arg user "${GITHUB_ACTOR:-local}" \
    '{ts: (now | todate), level: $level, msg: $msg, trace_id: $trace, user_id: $user}' >&2
}

if [ -f "$MAP_FILE" ]; then
  MAP_JSON="$(cat "$MAP_FILE")"
else
  log warn "owner map not found: $MAP_FILE (no mentions will be added)"
  MAP_JSON='{"users":{},"groups":{}}'
fi

# Resolve logins/groups to people. Unknown or empty owners fall back to the default group
# so that a notification never goes out without somebody to act on it.
USERS_JSON="$(jq -c --arg owners "$OWNERS" '
  . as $m
  | def expand: map(if startswith("group:") then ($m.groups[ltrimstr("group:")] // []) else [.] end) | add // [];
  def people($l): $l | unique | map($m.users[.] // empty);
  (people(($owners | split(" ") | map(select(length > 0)) | expand))) as $u
  | if ($u | length) > 0 then $u else people($m.groups.default // []) end
' <<<"$MAP_JSON")" || { log error "owner map is not valid JSON"; USERS_JSON='[]'; }

deliver() { # $1=platform $2=webhook url ; payload on stdin
  if [ "${NOTIFY_DRY_RUN:-0}" = "1" ]; then
    log info "dry-run platform=$1"
    jq -c --arg p "$1" '{platform: $p, payload: .}'
    return 0
  fi
  local code
  # Never echo the webhook URL or curl's own messages: the URL is a credential.
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
          --data-binary @- "$2" 2>/dev/null)" || code="000"
  case "$code" in
    2*) log info "sent platform=$1" ;;
    *)  echo "::warning::$1 notification failed (HTTP $code)"; log warn "send failed platform=$1 http=$code" ;;
  esac
}

sent=0

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  # Escape &, < and > so external text cannot inject <!channel> or links.
  esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
  t="$(printf '%s' "$TITLE" | esc)"; b="$(printf '%s' "$TEXT" | esc)"
  jq -n --arg t "$t" --arg b "$b" --arg u "$URL" --argjson users "$USERS_JSON" '
    ($users | map(select(.slack) | "<@" + .slack + ">") | join(" ")) as $m
    | {text: (($m | if length > 0 then . + " " else "" end) + ":raised_hand: *" + $t + "*\n" + $b + "\n<" + $u + "|Open>")}
  ' | deliver slack "$SLACK_WEBHOOK_URL"
  sent=$((sent + 1))
fi

if [ -n "${TEAMS_WEBHOOK_URL:-}" ]; then
  # NOTE: mentions use msteams.entities as documented for incoming webhooks; verify in your tenant.
  jq -n --arg t "$TITLE" --arg b "$TEXT" --arg u "$URL" --argjson users "$USERS_JSON" '
    ($users | map(select(.email))) as $us
    | {type: "message",
       attachments: [{
         contentType: "application/vnd.microsoft.card.adaptive",
         content: {
           type: "AdaptiveCard",
           "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
           version: "1.4",
           body: ((if ($us | length) > 0 then [{type: "TextBlock", wrap: true, text: ($us | map("<at>" + .name + "</at>") | join(" "))}] else [] end)
                  + [{type: "TextBlock", weight: "Bolder", wrap: true, text: $t},
                     {type: "TextBlock", wrap: true, text: $b}]),
           actions: [{type: "Action.OpenUrl", title: "Open", url: $u}],
           msteams: {entities: ($us | map({type: "mention", text: ("<at>" + .name + "</at>"), mentioned: {id: .email, name: .name}}))}
         }}]}
  ' | deliver teams "$TEAMS_WEBHOOK_URL"
  sent=$((sent + 1))
fi

[ "$sent" -gt 0 ] || log warn "no webhook configured (set SLACK_WEBHOOK_URL and/or TEAMS_WEBHOOK_URL)"
exit 0
