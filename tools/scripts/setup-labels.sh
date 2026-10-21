#!/usr/bin/env bash
# Create (or update) the labels the pipeline uses. Safe to run repeatedly.
# usage: setup-labels.sh [--repo owner/name]
set -euo pipefail

repo_args=()
if [ "${1:-}" = "--repo" ]; then repo_args=(--repo "${2:?--repo needs owner/name}"); fi

create() { # name color description
  gh label create "$1" --color "$2" --description "$3" --force "${repo_args[@]}"
}

create "ai:plan"             "1d76db" "Human: ask the AI for clarification, research and a plan"
create "needs:clarification" "fbca04" "AI is waiting for answers to its questions"
create "needs:plan-approval" "fbca04" "AI plan is ready for human review"
create "plan-approved"       "0e8a16" "Human: approve the plan so the AI may implement it"
echo "labels ready"
