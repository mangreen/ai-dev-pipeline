#!/usr/bin/env bash
# Shared test utilities: fixtures, mock webhook server, fake `gh`.
# Expects $ROOT (repo root) and $TMP (per-test temp dir) from the runner.

export NO_PROXY="127.0.0.1,localhost" no_proxy="127.0.0.1,localhost"

# Fake secrets are assembled at runtime so the repository never contains a
# realistic-looking credential literal (secret scanners stay quiet).
fake_password_line() { printf '%s' "const pass""word = \"Zx9-not-a-real-value\";"; }
fake_apikey_line()   { printf '%s' "api_""key: \"Zx9-not-a-real-value\""; }
fake_sk_token()      { printf '%s' "sk""-$(printf 'A%.0s' $(seq 1 30))"; }
fake_pem_header()    { printf '%s' "-----BEGIN RSA PRIV""ATE KEY-----"; }

# Owner map used by notify tests (independent of the user-edited real map).
write_owner_map() {
  cat > "$1" <<'JSON'
{
  "users": {
    "alice-gh": { "name": "Alice Chen", "slack": "U01AAAAAAA", "email": "alice@example.test" },
    "bob-gh":   { "name": "Bob Lin",    "slack": "U02BBBBBBB", "email": "bob@example.test" },
    "carol-gh": { "name": "Carol Wu",   "email": "carol@example.test" }
  },
  "groups": { "default": ["alice-gh"], "deploy": ["alice-gh", "bob-gh"] }
}
JSON
}

start_mock() {
  : > "$TMP/requests.jsonl"
  python3 "$ROOT/tests/helpers/mock_webhook.py" "$TMP/requests.jsonl" "$TMP/port" &
  MOCK_PID=$!
  for _ in $(seq 1 50); do [ -s "$TMP/port" ] && break; sleep 0.1; done
  MOCK_URL="http://127.0.0.1:$(cat "$TMP/port")"
  export MOCK_URL MOCK_PID
}

stop_mock() { [ -n "${MOCK_PID:-}" ] && kill "$MOCK_PID" 2>/dev/null || true; }

# Prints the `run:` scripts of a job from a workflow file.
step_script() { python3 -I "$ROOT/tests/helpers/extract_step.py" "$1" "$2"; }

use_fake_gh() { export PATH="$ROOT/tests/helpers/fake_bin:$PATH"; }
