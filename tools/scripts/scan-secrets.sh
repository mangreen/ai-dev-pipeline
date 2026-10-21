#!/usr/bin/env bash
# Code Review Gate for hard-coded secrets: scans ADDED lines of a unified diff.
#
# usage:
#   scan-secrets.sh --stdin          read a unified diff from stdin
#   scan-secrets.sh --base <ref>     scan `git diff <ref>...HEAD`
#
# Exit codes: 0 clean, 1 findings, 2 usage/git error.
# Findings never print the matched value.
#
# NOTE: rules follow the engineering standard (section 4.3) with two refinements:
#   * sk- tokens need 20+ token characters and must not be inside a word or a kebab-case name
#     (the raw `sk-[a-zA-Z0-9]` also matches "risk-based" and "ERR-..-sk-regex-..", see ERR-20261021).
#   * quoted values must be non-empty.
# Placeholders (`your-api-key-here`, `changeme`, `${VAR}`, `<name>`, env lookups) are allowed.
# This is a fast first line of defence; gitleaks in CI is the second.
set -uo pipefail
((BASH_VERSINFO[0] >= 4)) || { echo "bash >= 4 is required (macOS: brew install bash)" >&2; exit 2; }

usage() { echo "usage: $0 --stdin | --base <ref>" >&2; exit 2; }
[ $# -ge 1 ] || usage

case "$1" in
  --stdin) source_cmd=(cat) ;;
  --base)  [ $# -eq 2 ] || usage; source_cmd=(git diff -U0 --no-color "$2...HEAD") ;;
  *) usage ;;
esac

Q="[\"']"; NQ="[^\"']"
re_password="password${Q}?[[:space:]]*[:=][[:space:]]*${Q}${NQ}+${Q}"
re_secret="secret${Q}?[[:space:]]*[:=][[:space:]]*${Q}${NQ}+${Q}"
re_apikey="api[_-]?key${Q}?[[:space:]]*[:=][[:space:]]*${Q}${NQ}+${Q}"
re_sk='(^|[^A-Za-z0-9_-])sk-[A-Za-z0-9_-]{20,}'
re_pem='-----BEGIN [A-Z ]*PRIVATE KEY-----'
re_placeholder='your-[a-z0-9_-]+-here|changeme|placeholder|\$\{[^}]*\}|<[a-z0-9_ -]+>|process\.env|os\.environ|getenv'

# Step 1 (awk): turn the diff into "path<TAB>line<TAB>content" for every added line.
# Hunk counters are honoured so that an added line such as "++ x" is not mistaken for a header.
extract_added() {
  awk '
    function parse_hunk(h,   s, n, p) {
      if (match(h, /-[0-9]+(,[0-9]+)?/)) { s = substr(h, RSTART + 1, RLENGTH - 1); n = split(s, p, ","); rem_old = (n > 1) ? p[2] + 0 : 1 }
      if (match(h, /\+[0-9]+(,[0-9]+)?/)) { s = substr(h, RSTART + 1, RLENGTH - 1); n = split(s, p, ","); line = p[1] + 0; rem_new = (n > 1) ? p[2] + 0 : 1 }
    }
    rem_old > 0 || rem_new > 0 {
      c = substr($0, 1, 1)
      if (c == "+")      { printf "%s\t%d\t%s\n", file, line, substr($0, 2); line++; rem_new-- }
      else if (c == "-") { rem_old-- }
      else if (c == "\\") { }
      else               { line++; rem_old--; rem_new-- }
      next
    }
    /^\+\+\+ / { file = substr($0, 7); if ($0 ~ /\/dev\/null/) file = ""; next }
    /^@@/      { parse_hunk($0); next }
  '
}

# Step 2 (bash): apply the rules to each added line.
status=0
while IFS=$'\t' read -r path lineno content; do
  [ -n "$path" ] || continue
  lc="${content,,}"
  rule=""
  if   [[ $content =~ $re_pem ]]; then rule="private-key"
  elif [[ $content =~ $re_sk ]]; then rule="sk-token"
  elif ! [[ $lc =~ $re_placeholder ]]; then
    if   [[ $lc =~ $re_password ]]; then rule="password"
    elif [[ $lc =~ $re_secret   ]]; then rule="secret"
    elif [[ $lc =~ $re_apikey   ]]; then rule="api-key"
    fi
  fi
  if [ -n "$rule" ]; then
    echo "FINDING ${path}:${lineno} rule=${rule}" >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error file=${path},line=${lineno}::possible hard-coded secret (rule: ${rule})"
    status=1
  fi
done < <("${source_cmd[@]}" | extract_added)

# `git diff` failure is not visible through process substitution; re-check the ref explicitly.
if [ "$1" = "--base" ] && ! git rev-parse --verify --quiet "$2" >/dev/null; then
  echo "unknown git ref: $2" >&2; exit 2
fi
exit "$status"
