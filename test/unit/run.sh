#!/usr/bin/env bash
# Runs every shell unit suite. Mirrors the guardrails plugin's own runner so the
# documented test command stays one entry per suite directory, not per file.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
for t in "$DIR"/test_*.sh; do echo "== $t"; zsh "$t" || rc=1; done
exit $rc
