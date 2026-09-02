# Claude.md

## Spec and plan locations

Override superpowers skill defaults:

- **Specs** (from `superpowers:brainstorming`): save to `.claude/specs/YYYY-MM-DD-<topic>-design.md`
- **Plans** (from `superpowers:writing-plans`): save to `.claude/plans/YYYY-MM-DD-<feature-name>.md`

Never save specs or plans to `docs/`. These paths are excluded from git via the global gitignore (`~/.config/git/ignore`).

## Code change workflow

All non-trivial code changes follow this flow:

1. **Worktree** — invoke `superpowers:using-git-worktrees` to create an isolated workspace. Never edit in the main checkout.
2. **Commits** — use the `guardrails:commit` skill for every commit. Atomic, conventional-commit format, one logical change per commit.
3. **Rebase (if needed)** — before opening a PR, invoke the `guardrails:rebase` skill to compact noisy development commits into a clean, reviewable history. Skip if the branch is already clean.
4. **Pre PR checks** – Before pushing, invoke the pre-pr-check skill to sweep for unencrypted secrets, test coverage, readability, etc.
5. **Draft PR** — use the `guardrails:draft-pr` skill. PRs are always opened as drafts; promotion to ready-for-review is the user's call.

Never push directly to `main`. Never skip the PR step for shared repos.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- No extensive comment blocks, use the guardrails:concise-comments skill.
- No placater tests, tests should meaningfully excercise the code.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
