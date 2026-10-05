#!/usr/bin/env bash
# Keeps one open issue labelled `mutation` in step with the latest test/mutate.sh report.
# Usage: test/mutation-issue.sh REPORT_FILE RUN_URL  (needs gh with issues: write)
# See docs/design/coverage-and-mutation.md
set -euo pipefail

report=${1:?mutation-issue needs the report file}
run_url=${2:?mutation-issue needs the run URL}
[[ -r $report ]] || { echo "mutation-issue: cannot read $report" >&2; exit 1; }
awk '$NF == "TOTAL" && $1 ~ /^[0-9]+\/[0-9]+$/ { split($1, a, "/"); n = a[2] } END { exit !(n > 0) }' "$report" ||
  { echo "mutation-issue: $report scored no mutants" >&2; exit 1; }

open=$(gh issue list --author app/github-actions --label mutation --state open --json number --jq '.[0].number // empty')

if grep -q '^survived ' "$report"; then
  body=$(mktemp)
  trap 'rm -f "$body"' EXIT
  {
    echo "The weekly mutation run found mutants that no test kills. Each one needs a test that"
    echo "kills it, or an entry with a reason in \`test/mutants-ignore.tsv\`."
    echo
    echo '~~~~'
    cat "$report"
    echo '~~~~'
    echo
    echo "Run: $run_url"
  } >"$body"
  if [[ -n $open ]]; then
    gh issue edit "$open" --body-file "$body"
  else
    gh label create mutation --description "Surviving mutants from the weekly mutation run" --force
    gh issue create --title "Mutation testing: surviving mutants" --label mutation --body-file "$body"
  fi
elif [[ -n $open ]]; then
  gh issue close "$open" --comment "No surviving mutants in $run_url"
fi
