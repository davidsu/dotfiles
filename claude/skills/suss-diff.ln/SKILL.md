---
name: suss-diff
description: >
  Show the user the diff of a worktree's branch: opens a new iTerm tab right of the
  current agent's tab, runs gdiffbranch (nvim file list of what changed since the branch
  point) in that worktree, and focuses it. Invoke as /suss-diff [worktree] [gdiffbranch args].
allowed-tools: Bash
---

# suss-diff

```
~/.claude/skills/suss-diff/scripts/suss-diff <worktree> [gdiffbranch args...]
```

- `<worktree>`: the worktree the user means. Given in the invocation → use it. Otherwise the one
  you work in (your pwd or the worktree you edited). Not sure which → ask, don't guess.
- Extra args go to `gdiffbranch` (`gdc -h`): none = branch point vs working tree, `HEAD~1`, `<a> <b>`.
- Runs from your own Bash tool: the new tab lands right of your tab (`$ITERM_SESSION_ID`) and takes focus.
