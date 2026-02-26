---
name: prdiff
description: Show the full PR diff (all changes on this branch vs origin/main). Use when reviewing a PR, understanding branch changes, or preparing a PR summary.
argument-hint: [-- extra git-diff flags]
---

# PR Diff (merge-base against origin/main)

## Diff stats
!`git diff --no-color --stat $(git merge-base HEAD origin/main)`

## Full diff
!`git diff --no-color -U0 $(git merge-base HEAD origin/main) $ARGUMENTS`
