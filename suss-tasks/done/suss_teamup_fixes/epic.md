closed
# 🪝 suss-teamup: every spawn colors, swallowed recv, sleep never closes David's tab

## Summary

Two suss-teamup fixes ordered by David on 2026-10-15 ("if we need fix in suss-teamup then lets already take care of it"). Leads spawned with `--no-steal` came up colorless, and a lead lost a peer's message by piping `recv` to `/dev/null`.

## 🎨 Fix 1: `--no-steal` keeps the iTerm tab color

- Before: `--no-steal` (alias `--no-color`) skipped all coloring, so lead.temp.24 and lead.25 came up colorless.
- The tab color is an escape sequence written to the tab's tty (`bin/iterm_tab_style`), focus-free; only claude's typed `/color` needs keystrokes.
- Now [paint_iterm_tab](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/scripts/teamup-spawn#L85) runs on [--no-steal](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/scripts/teamup-spawn#L234) too, and codex keeps its tab color. Docs: `resources/spawn.md`, `resources/known_team_roles.md`.
- Commit [918f947](https://github.com/davidsu/dotfiles/commit/918f947), test [spawn_no_steal_tab_color_test.sh](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/tests/spawn_no_steal_tab_color_test.sh).

### Superseded: the flag is gone ([46e7c8d](https://github.com/davidsu/dotfiles/commit/46e7c8d))

- David, 2026-10-15 11:26 (relayed by lead.25): "remove that flag, no such thing as spawn and not color!"
- `--no-steal` and `--no-color` are removed. Every iTerm spawn paints the tab and types `/color` with iTerm's per-session `write text` (no `activate`, no System Events keystrokes), so none of it takes focus.
- Ghostty still keystrokes `/color` (it has no per-session write), which takes focus.
- [spawn_colors_test.sh](https://github.com/davidsu/dotfiles/blob/46e7c8d/claude/skills/suss-teamup.ln/tests/spawn_colors_test.sh) replaces the no-steal test: tab + `/color` on every spawn, no focus-taking script, and the old flags refused.
- The sessions left colorless by the flag: teamup.fixes got yellow (tab + `/color`), lead.25 got its blue tab; David set its `/color blue` himself. A deferred loop to type it was killed before it typed: never type into a tab David works in (the ctrl-U would wipe his input).

## 📭 Fix 2: `recv > /dev/null` reads nothing

### 🔍 What really happened

- lead.25's understanding-check posted fine as suss-lead #314 (07:59:32Z; its first try had exited 3 and it resent).
- lead.24's transcript (`/Users/davidsu/.claude/projects/-Users-davidsu-projects-apper/fff8b680-2d84-44c8-a5dc-cd36f91b1052.jsonl`) shows, at 07:59:40.934Z: `$T recv suss-lead --as lead.24 >/dev/null; $T say suss-lead --as lead.24 -- "…"`. The swallowed recv advanced its cursor past #314, the say went through as #315, and #314 was never seen.
- So it was not a misread exit-3 refusal.

### 🔧 The fix

- [refuse_recv_into_dev_null](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/scripts/teamup#L536): when stdout is `/dev/null` (`[ /dev/stdout -ef /dev/null ]`), recv prints `✗ NOT READ (exit 3)` on stderr and leaves the cursor alone, so the next say refuses and shows the missed lines.
- `recv --discard` is the explicit opt-out for scripts that post but never read: `teamup-slack-watch` and `teamup-gh-watch` now pass it.
- The exit-3 post refusal now [leads with](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/scripts/teamup#L550) `✗ NOT POSTED (exit 3)`.
- Docs: `resources/commands.md`, `resources/mailbox.md`.
- Commit [4ee3bfa](https://github.com/davidsu/dotfiles/commit/4ee3bfa), test [discarded_recv_test.sh](https://github.com/davidsu/dotfiles/blob/4ee3bfa/claude/skills/suss-teamup.ln/tests/discarded_recv_test.sh), which reproduces lead.24's exact `recv >/dev/null; say` line.

### ⚠️ Not covered

- A recv piped into a command that drops its output (`| head -0`, `| rg -v …` filtering the line out) can't be detected and still advances the cursor.
- `teamup-gh-watch` is untracked (another agent's work in progress): its `--discard` edit sits in the working tree only.

## 🛑 Fix 3: sleep never closes the tab David is typing in

- David, 2026-10-15 11:17 (relayed by lead.25): "where is fzf-terminal? I was typing a request to him. this keeps happening."
- Cause: fzf.terminal ran `teamup-sleep --force` (the SKILL.md sleep row) while David typed into its tab. `is_focused` (front window's current tab + input within 120 s) lived inside `is_busy`, which `--force` overrides.
- Now [sleep_if_allowed](https://github.com/davidsu/dotfiles/blob/c638c9e/claude/skills/suss-teamup.ln/scripts/teamup-sleep#L208) checks focus first: a hard stop no flag overrides, self-sleep included, exit 1. `--force` overrides only the softer checks.
- The title match already covers claude's glyphs: live iTerm titles read `◐ teamup.fixes (claude)` and `✳ fzf.terminal (claude)`, and the match is `*" <handle> (claude)"`.
- Docs: `resources/agent_lifecycle.md`, the SKILL.md sleep row.
- Commit [c638c9e](https://github.com/davidsu/dotfiles/commit/c638c9e), test [sleep_focused_tab_test.sh](https://github.com/davidsu/dotfiles/blob/c638c9e/claude/skills/suss-teamup.ln/tests/sleep_focused_tab_test.sh).

**b44sync**: never

---
**Created by**: teamup.fixes (2026-10-15)
**Updated by**: teamup.fixes (2026-10-15), teamup.fixes (2026-10-15)
