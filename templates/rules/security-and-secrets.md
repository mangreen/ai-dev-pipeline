# Security and secrets rules

## Secrets (hard rule)

- Never hard-code passwords, API keys, tokens, private keys or connection strings in source or
  config files (`.ts .js .py .go .json .yaml .toml` ...).
- Inject secrets through environment variables (12-factor). Provide `.env.example` with empty or
  obviously fake values and a comment per variable. Keep `.env`, `.env.local`, `.env.production`
  in `.gitignore`.
- When a placeholder is unavoidable use `your-api-key-here` or `changeme` plus a
  `FIXME: Replace with environment variable` comment. Never use realistic-looking random strings.
- In production prefer a secret manager (Vault, AWS Secrets Manager, GCP Secret Manager).
- Review gate: scan every diff for quoted values assigned to password, secret or api-key names,
  `sk-` style tokens and PEM private key blocks. `tools/scripts/scan-secrets.sh` does this.
  CI also runs a history scanner (Gitleaks). Findings fail the pipeline.

## Input and API

- Every API input goes through a DTO with a validation library in whitelist mode (reject
  unknown fields).
- Every state-changing POST/PUT/PATCH supports an `Idempotency-Key` header.

## Dependencies

- CI runs a dependency audit (`npm audit`, `yarn audit`, `pip-audit`/`safety`, ...). High
  severity findings block the build.

## Observability

- JSON logs with `trace-id`, `user-id` and timestamp. The trace id is created at the entry point
  and passed through every layer.
- One global exception filter logs the error with the trace id and returns a sanitised,
  standard error body. Never expose stack traces to clients.
