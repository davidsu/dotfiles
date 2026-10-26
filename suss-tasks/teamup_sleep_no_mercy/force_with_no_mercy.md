closed
# 🗡️ teamup-sleep `--force-with-no-mercy`: sleep the agent, no guard can refuse

## Summary

On 2026-10-26 David told an agent, in its own tab, to finish and go to sleep. It ran `teamup-sleep --force` and got `not closing …: David is in its tab right now (focused, typed within 120 s). No flag overrides this.` David: "current --force doesn't force enough and it became a mess. make a --force-with-no-mercy, it kills no matter what".

## 🧭 What exists today

- `--force` overrides only `is_busy` (David spoke to it lately, a peer waits on it, it spoke in the last minute). Agents pass it on every self-sleep, because a self-sleep is always "busy".
- `is_focused` (the tab is iTerm's current tab and David touched the keyboard in the last 120 s) refuses with no override. It was added after an owner slept itself with `--force` while David was typing a request into its tab (dotfiles commit `c638c9e8`). Keep that guard for plain `--force`.
- Code: `claude/skills/suss-teamup.ln/scripts/teamup-sleep`, function `sleep_if_allowed` and the flag parsing at the bottom. Tests: `claude/skills/suss-teamup.ln/tests/sleep_*_test.sh` (all three pass today).

## ✅ What to build

1. `--force-with-no-mercy`: skips `is_focused` and `is_busy`, then sleeps. It still prints the reasons it overrode, as `--force` does.
2. `--force` and no flag: behave exactly as today.
3. Docs say when to use it: only when David himself ordered the sleep (typed in the agent's tab, or his words relayed). A lead's own "go to sleep" stays `--force`. Places: `SKILL.md` (the `sleep` row), `resources/agent_lifecycle.md` (the "never closes the tab David is in" paragraph), the usage line in the script.
4. Extend `tests/sleep_focused_tab_test.sh`: the new flag closes the focused tab; `--force` still does not.

## 🚚 Ship

Dotfiles is David's own repo: stage only these files (the checkout holds others' uncommitted work), commit and push straight to `master`, no PR.

## ✔️ Done

Shipped by teamup.mercy.owner (2026-10-26): `sleep_if_allowed` takes the flag itself (`''`, `--force`, `--force-with-no-mercy`); the focused-tab refusal now names the one flag that overrides it. All three `tests/sleep_*_test.sh` pass.

---
**Created by**: actors.owner.2 (2026-10-26), at David's ask
**b44sync**: never
