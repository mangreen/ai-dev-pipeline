# Developer entry points. CI runs exactly these targets.
SHELL := /usr/bin/env bash
SH_FILES := $(shell find . -name '*.sh' -not -path './.git/*' | sort) tests/helpers/fake_bin/gh
WORKFLOWS := $(wildcard .github/workflows/*.yml) $(wildcard templates/workflows/*.yml)

.PHONY: help test lint docs-check secrets-check check

help: ## show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ -/'

test: ## run every unit and integration test
	bash tests/run.sh

lint: ## shellcheck, yamllint, actionlint
	shellcheck -x $(SH_FILES)
	yamllint -c .yamllint.yml .github templates .claude
	actionlint $(WORKFLOWS)

docs-check: ## memory links and relative Markdown links
	bash tools/scripts/check-memory-links.sh .agents/memories
	bash tools/scripts/check-doc-links.sh .

secrets-check: ## scan the diff against main for hard-coded secrets
	bash tools/scripts/scan-secrets.sh --base main

check: lint test docs-check ## everything except the secrets scan
