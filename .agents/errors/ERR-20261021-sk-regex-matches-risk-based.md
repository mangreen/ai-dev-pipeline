# ERR: Secret-scan regex `sk-[a-zA-Z0-9]` flags ordinary words
Date: 2026-10-21
Severity: Medium

## Description
The engineering standard (section 4.3) lists `sk-[a-zA-Z0-9]` as the pattern for OpenAI-style
keys. Applied literally to a diff it also matches harmless text such as "risk-based" or
"task-oriented", so the Code Review Gate fails on documentation.

## Root Cause
The pattern has no word boundary and no minimum token length.

## Solution
`tools/scripts/scan-secrets.sh` requires the `sk-` not to be preceded by a letter or digit and
to be followed by at least 20 token characters. Test:
`should_not_flag_when_word_contains_sk_dash_like_risk_based`.

A second false positive appeared when the scanner flagged this very error's file name
(`ERR-20261021-sk-regex-matches-risk-based.md`): `-sk-regex-matches-risk-based` is `sk-` followed by
20+ token characters. The preceding character must therefore not be a letter, digit, `_` or `-`.
Tests: `should_not_flag_when_sk_dash_is_part_of_a_kebab_case_file_name` and
`should_still_flag_token_when_it_follows_an_equals_sign_or_quote`.

## Prevention
Tune a rule only together with a test that has a true positive and a look-alike false positive.
Keep Gitleaks in CI as the second line of defence.
