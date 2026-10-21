ready
# 🔀 Open gdiffbranch in a new tab right of the agent's tab

## Summary

David asked for `/suss-diff`: open a new iTerm tab right of the current agent's tab, in the right
worktree, run `gdiffbranch` there and focus it. The agent passes its worktree, or asks.

## 🛠️ Shape

- `claude/skills/suss-diff.ln/SKILL.md` + `scripts/suss-diff <worktree> [gdiffbranch args]`, linked to `~/.claude/skills/suss-diff` via `links.toml`
- `gdiffbranch` is a zsh function (`zsh/sources/git.zsh`, runs `nvim -c GDiffBranch`), so it is typed into the new tab's interactive shell
- Tab placement reuses `bin/term_spawn --after $ITERM_SESSION_ID` (which calls `bin/iterm_tab_move_after`); no `--background`, so the new tab keeps focus

**b44sync**: never

---
**Created by**: suss.diff (2026-10-21)
