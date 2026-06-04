---
name: suss-cleanup
description: >
  Delete local git branches and worktrees that have no related open pull
  request. Load when asked to clean up branches/worktrees, prune stale
  branches, or "delete branches with no open PR". Protected branches
  (do_not_delete / backup / preserve / keep-me, the default branch, and the
  current branch) are always kept.
---

# Local Branch & Worktree Cleanup

Deletes every local branch whose name does **not** match an open PR's head
branch, and removes the worktree checked out on it first when one exists.

## What is protected (never deleted)

- The default branch (`origin/HEAD`) and the currently checked-out branch.
- Any branch matching `/do.?not.?delete|dont.?delete|backup|preserve|keep.?me/i`.
  Override the pattern with `SUSS_CLEANUP_PROTECTED_REGEX`.
- A branch checked out in the **primary** worktree (the repo root).

A branch is kept when its exact name equals the `headRefName` of any open PR
(`gh pr list --state open`).

## How to run

Always dry-run first, show the plan to the user, get explicit confirmation,
then execute. The deletion is destructive (`git branch -D`).

```bash
# 1. Dry run — prints the plan, makes no changes
scripts/cleanup_branches.sh

# 2. After the user confirms — actually delete
scripts/cleanup_branches.sh --execute
```

Run from inside the repository whose branches you want to clean.

## Notes

- Branch deletion uses `git branch -D` (force) — squash-merged branches are not
  recognized as merged by git, so a soft `-d` would refuse them. Deleted local
  branches are recoverable via `git reflog` (~90 days) and re-fetchable when the
  remote still has them.
- Worktree removal is **not** forced: a worktree with uncommitted/untracked
  changes is reported as a failure and left intact rather than silently
  destroying unpushed work. Resolve it by hand if you truly want it gone.
- Requires the `gh` CLI authenticated against the repo's GitHub remote.
