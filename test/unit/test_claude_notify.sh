#!/usr/bin/env zsh
# Builds the real claude-notify and checks the exit code that guards a launch without a title and body.
# A post needs a logged-in user's Notification Center, so that path stays a manual check.
# See docs/design/claude-tmux-state.md

REPO="${0:A:h}/../.."
FAILS=0

# Other platforms can have swiftc but not the UserNotifications framework.
[[ $(uname) == Darwin ]] && command -v swiftc >/dev/null || { echo "not macOS with swiftc — skipping"; exit 0; }

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT
swiftc -O -o "$D/claude-notify" "$REPO/home/files/claude/claude-notify.swift" || { echo "FAILED: claude-notify does not compile"; exit 1; }

echo "--- without exactly a title and a body it exits 64, as when a click on a banner relaunches it"
for args in "" "title" "title body extra"; do
  "$D/claude-notify" ${=args}; rc=$?
  [[ $rc == 64 ]] || die usage "exited $rc with arguments '$args'"
done

[[ $FAILS == 0 ]] && echo "OK: claude-notify" || { echo "FAILED: claude-notify"; exit 1 }
