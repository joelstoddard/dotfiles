#!/usr/bin/env zsh
# Tests claude-statusline against a fake oh-my-posh and fake transcripts dated relative to now.
# See docs/design/claude-cache-statusline.md

REPO="${0:A:h}/../.."
SCRIPT="$REPO/home/files/claude/claude-statusline.sh"
FAILS=0

command -v jq >/dev/null || { echo "jq not installed — skipping"; exit 0; }

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

D=$(mktemp -d); mkdir "$D/bin"; trap 'rm -rf "$D"' EXIT
# Echoes its stdin back, so a test can see the JSON reached oh-my-posh.
printf '#!/usr/bin/env bash\nprintf "OMP:%%s" "$(cat)"\n' > "$D/bin/oh-my-posh"; chmod +x "$D/bin/oh-my-posh"

# entry <seconds ago> <5m tokens written> <1h tokens written> — one assistant transcript line
entry() {
  jq -cn --argjson ago $1 --argjson m5 $2 --argjson h1 $3 '{type: "assistant", timestamp: (now - $ago | todate),
    message: {usage: {cache_read_input_tokens: 9000, cache_creation: {ephemeral_5m_input_tokens: $m5, ephemeral_1h_input_tokens: $h1}}}}'
}
user() { echo '{"type":"user","message":{"content":"hi"}}' }

# check <name> <expected suffix after the oh-my-posh output> — transcript lines on stdin
check() {
  cat > "$D/t.jsonl"
  local json="{\"transcript_path\":\"$D/t.jsonl\"}" out
  out=$(print -r -- "$json" | PATH="$D/bin:$PATH" bash "$SCRIPT")
  [[ $out == "OMP:$json$2" ]] || die "$1" "got '$out'"
}

{ entry 150 0 4000; user } | check "1h write, 2.5m ago: warm" "  |  cache warm 57m/1h"
{ entry 150 4000 0; user } | check "5m write, 2.5m ago: warm" "  |  cache warm 2m/5m"
{ entry 600 4000 0; user } | check "5m write, 10m ago: cold" "  |  cache cold/5m"
{ entry 4000 0 4000 } | check "1h write, 67m ago: cold" "  |  cache cold/1h"
{ entry 3000 0 4000; entry 630 0 0 } | check "read-only request keeps the earlier write's TTL" "  |  cache warm 49m/1h"
{ entry 3000 0 4000; entry 150 4000 0 } | check "the latest write sets the TTL" "  |  cache warm 2m/5m"
user | check "no request yet: cold" "  |  cache cold"
{ entry 120 0 0 } | check "TTL unknown: segment omitted" ""

out=$(print -r -- '{"transcript_path":"/nonexistent"}' | PATH="$D/bin:$PATH" bash "$SCRIPT")
rc=$?
[[ $out == 'OMP:{"transcript_path":"/nonexistent"}' && $rc == 0 ]] || die "missing transcript: line only, exit 0" "got '$out' rc=$rc"

for f in "$REPO/.claude/user-settings.json" "$REPO/.claude/settings.json"; do
  [[ $(jq -r '.statusLine.command' "$f") == claude-statusline ]] || die "wiring" "$f does not run claude-statusline"
  [[ $(jq -r '.statusLine.refreshInterval' "$f") == <-> ]] || die "wiring" "$f has no refreshInterval, so the line never turns cold while idle"
done

(( FAILS )) && exit 1
echo "  ok"
