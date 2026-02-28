---
name: prdiff
description: Show the full PR diff (all changes on this branch vs origin/main). Use when reviewing a PR, understanding branch changes, or preparing a PR summary.
argument-hint: [-- extra git-diff flags]
---

# PR Diff (merge-base against origin/main)

Run these two commands using the Bash tool (do NOT use `!` inline execution — the output must stay in tool results, not be printed to the user):

1. `git diff --no-color --stat $(git merge-base HEAD origin/main)`
2. `git diff --no-color -U0 $(git merge-base HEAD origin/main) $ARGUMENTS`

After reading the diff, summarize the changes for the user. Do NOT echo the raw diff back.
