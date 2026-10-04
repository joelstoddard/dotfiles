#!/usr/bin/env bash
# Runs every shell and Python unit suite, so the documented test command stays one entry
# per suite directory, not per file.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
for t in "$DIR"/test_*.sh; do echo "== $t"; zsh "$t" || rc=1; done
# The Python suites need PyYAML. uv supplies it without a project environment; CI installs it with pip instead.
if command -v uv >/dev/null; then py=(uv run --quiet --no-project --with pyyaml python3); else py=(python3); fi
echo "== Python suites"
"${py[@]}" -m unittest discover -s "$DIR" -p 'test_*.py' || rc=1
exit $rc
