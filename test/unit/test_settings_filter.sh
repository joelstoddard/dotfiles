#!/usr/bin/env zsh
# Tests the clean filter that keeps session state out of user-settings.json.
#
# Each case wires a throwaway repo with the real .gitattributes and the filter
# definition read out of home/git.nix, so the two cannot drift apart unnoticed.
# Ported from test_settings_filter.py, which drove the installer this branch
# removes. See docs/design/claude-settings-split.md

REPO="${0:A:h}/../.."
TRACKED=".claude/user-settings.json"
FAILS=0

command -v jq >/dev/null || { echo "jq not installed — skipping"; exit 0; }

# The one definition both git.nix and this test read.
CLEAN=$(sed -n 's/.*filter\."claude-settings"\.clean = "\(.*\)";/\1/p' "$REPO/home/git.nix")
[[ -n "$CLEAN" ]] || { echo "FAILED: no filter definition in home/git.nix"; exit 1; }

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → fresh repo in $D with the filter wired
  D=$(mktemp -d)
  git -C "$D" init -q
  cp "$REPO/.gitattributes" "$D/.gitattributes"
  git -C "$D" config filter.claude-settings.clean "$CLEAN"
  mkdir -p "$D/${TRACKED:h}"
  git -C "$D" add .gitattributes
  commit
}
write() { print -r -- "$1" > "$D/$TRACKED" }
stage() { write "$1"; git -C "$D" add "$TRACKED"; git -C "$D" show ":$TRACKED" }
# A no-op commit is a legitimate outcome here — the filter is what makes it one.
commit() { git -C "$D" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm seed >/dev/null 2>&1 || true }
cleanup() { rm -rf "$D" }

echo "--- model is stripped from the staged blob, other keys survive"
setup
blob=$(stage '{"model":"opus","effortLevel":"xhigh"}')
[[ $(print -r -- "$blob" | jq 'has("model")') == false ]] || die "strip" "model reached the blob"
[[ $(print -r -- "$blob" | jq -r .effortLevel) == xhigh ]] || die "strip" "effortLevel lost"
cleanup

echo "--- the working file keeps its model"
setup
stage '{"model":"opus"}' >/dev/null
[[ $(jq -r .model "$D/$TRACKED") == opus ]] || die "worktree" "working file lost its model"
cleanup

echo "--- keys are sorted, so a rewrite alone is not a diff"
setup
blob=$(stage '{"tui":"fullscreen","effortLevel":"xhigh","agent":"x"}')
keys=$(print -r -- "$blob" | jq -r 'keys_unsorted|join(",")')
[[ "$keys" == "agent,effortLevel,tui" ]] || die "sort" "keys not canonical: $keys"
cleanup

echo "--- switching model records nothing in history"
setup
stage '{"model":"opus","effortLevel":"xhigh"}' >/dev/null; commit
before=$(git -C "$D" rev-parse 'HEAD^{tree}')
write '{"model":"sonnet","effortLevel":"xhigh"}'
# git status still lists it — that is decided from stat, without running the
# filter — so committing is what proves the guarantee.
[[ -n $(git -C "$D" status --porcelain) ]] || die "history" "expected a stat-dirty tree"
git -C "$D" add -A; commit
[[ $(git -C "$D" rev-parse 'HEAD^{tree}') == "$before" ]] || die "history" "a model switch reached the tree"
cleanup

echo "--- reordering keys leaves nothing to commit"
setup
stage '{"effortLevel":"xhigh","tui":"fullscreen"}' >/dev/null; commit
write '{"tui":"fullscreen","effortLevel":"xhigh"}'
[[ -z $(git -C "$D" diff -- "$TRACKED") ]] || die "reorder" "reordering produced a diff"
cleanup

echo "--- a real setting change still shows up"
setup
stage '{"model":"opus","effortLevel":"xhigh"}' >/dev/null; commit
write '{"model":"opus","effortLevel":"low"}'
[[ $(git -C "$D" diff -- "$TRACKED") == *effortLevel* ]] || die "signal" "the filter swallowed a real edit"
cleanup

[[ $FAILS == 0 ]] && echo "OK: settings-filter" || { echo "FAILED: settings-filter"; exit 1 }
