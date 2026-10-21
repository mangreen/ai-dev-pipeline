#!/usr/bin/env bash
# Static guard-rail tests over the workflow templates (security and cost controls).

WF="$ROOT/templates/workflows"

require_templates() { ls "$WF"/*.yml >/dev/null 2>&1 || fail "no workflow templates found in $WF"; }

should_not_interpolate_untrusted_event_fields_when_building_scripts_or_prompts() {
  require_templates
  # Titles, bodies, comments and branch names are attacker-controlled text. They may only be
  # read inside the agent via `gh`, or in `if:` conditions - never expanded into run/prompt text.
  hits="$(grep -nE 'github\.event\.(issue\.(title|body)|comment\.body|pull_request\.(title|body|head\.(ref|label))|head_commit\.message)|github\.head_ref' "$WF"/*.yml \
          | grep -vE '^\S+:[0-9]+:\s*if:' || true)"
  assert_eq "" "$hits"
}

should_define_least_privilege_permissions_for_every_job() {
  require_templates
  python3 -I - "$WF" <<'PY'
import glob, sys, yaml
bad = []
for path in sorted(glob.glob(sys.argv[1] + "/*.yml")):
    for job, spec in yaml.safe_load(open(path))["jobs"].items():
        if "permissions" not in spec:
            bad.append(f"{path}:{job}")
sys.exit("jobs without explicit permissions: " + ", ".join(bad) if bad else 0)
PY
}

should_set_timeout_on_every_job_when_workflow_runs_an_ai_agent() {
  require_templates
  python3 -I - "$WF" <<'PY'
import glob, sys, yaml
bad = []
for path in sorted(glob.glob(sys.argv[1] + "/ai-*.yml")):
    for job, spec in yaml.safe_load(open(path))["jobs"].items():
        if "timeout-minutes" not in spec:
            bad.append(f"{path}:{job}")
sys.exit("jobs without timeout-minutes: " + ", ".join(bad) if bad else 0)
PY
}

should_serialize_runs_per_issue_when_workflow_runs_an_ai_agent() {
  require_templates
  python3 -I - "$WF" <<'PY'
import glob, sys, yaml
bad = [p for p in sorted(glob.glob(sys.argv[1] + "/ai-*.yml")) if "concurrency" not in yaml.safe_load(open(p))]
sys.exit("workflows without concurrency: " + ", ".join(bad) if bad else 0)
PY
}

should_not_let_agent_jobs_merge_or_approve_when_tools_are_allowlisted() {
  require_templates
  hits="$(grep -nE 'gh pr (merge|review --approve)|gh api' "$WF"/ai-*.yml || true)"
  assert_eq "" "$hits"
}

should_require_human_environment_approval_when_deploying_to_production() {
  assert_contains "$(cat "$WF/deploy.yml")" "environment: production"
}

should_checkout_notify_script_from_base_branch_when_notifying_from_pull_request_context() {
  assert_contains "$(cat "$WF/ai-review.yml")" "github.event.pull_request.base.ref"
}
