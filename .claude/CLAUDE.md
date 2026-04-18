# Global instructions

## Spec and plan locations

Override superpowers skill defaults:

- **Specs** (from `superpowers:brainstorming`): save to `.claude/specs/YYYY-MM-DD-<topic>-design.md`
- **Plans** (from `superpowers:writing-plans`): save to `.claude/plans/YYYY-MM-DD-<feature-name>.md`

Never save specs or plans to `docs/`. These paths are excluded from git via the global gitignore (`~/.config/git/ignore`).

## Code change workflow

All non-trivial code changes follow this flow:

1. **Worktree** — invoke `superpowers:using-git-worktrees` to create an isolated workspace. Never edit in the main checkout.
2. **Commits** — use the `commit` skill for every commit. Atomic, conventional-commit format, one logical change per commit.
3. **Rebase (if needed)** — before opening a PR, invoke the `rebase` skill to compact noisy development commits into a clean, reviewable history. Skip if the branch is already clean.
4. **Draft PR** — use the `draft-pr` skill. PRs are always opened as drafts; promotion to ready-for-review is the user's call.

Never push directly to `main`. Never skip the PR step for shared repos.
