"""Print the `run:` scripts of one job in a GitHub Actions workflow file.

usage: extract_step.py <workflow.yml> <job-id>
Requires PyYAML (pre-installed on most images; `pip install pyyaml` otherwise).
"""
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as f:
    workflow = yaml.safe_load(f)
for step in workflow["jobs"][sys.argv[2]]["steps"]:
    if "run" in step:
        print(step["run"])
