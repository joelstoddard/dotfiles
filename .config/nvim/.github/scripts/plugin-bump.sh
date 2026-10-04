#!/bin/sh
# Prints the update PR's body: each plugin whose revision changed, with a compare link, then the suite's result.
# Usage: sh .github/scripts/plugin-bump.sh <suite-exit-code> <suite-log>
set -eu
status=$1
log=$2

echo 'Weekly plugin update from `sh tests/run.sh --update`.'
echo
git show HEAD:nvim-pack-lock.json | jq -rn --slurpfile new nvim-pack-lock.json 'input as $old
  | ($old.plugins + $new[0].plugins | keys) as $names
  | $names[] as $name
  | ($old.plugins[$name].rev // "") as $from | ($new[0].plugins[$name].rev // "") as $to
  | select($from != $to)
  | if $from == "" then "- **\($name)**: new at `\($to[0:7])`"
    elif $to == "" then "- **\($name)**: removed"
    else "- **\($name)**: `\($from[0:7])` → `\($to[0:7])` ([compare](\($new[0].plugins[$name].src)/compare/\($from)...\($to)))"
    end'
echo
if [ "$status" = 0 ]; then
	echo "**Tests:** passed on the updated plugins."
else
	echo "**Tests:** failed (exit $status) on the updated plugins; this run's job is red."
fi
echo
echo '```'
perl -pe 's/\e\[[0-9;]*m//g' "$log" | grep -a -E 'Total number of cases|Fails \(|FAIL' | head -20 || true
echo '```'
