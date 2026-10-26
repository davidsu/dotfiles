# ⏪ How an agent rewinds its own conversation (2026-10-26)

## Summary

Claude Code's rewind menu (`Esc` `Esc` on an empty input, or `/rewind`) lists every prompt of the session. "Restore conversation" at a prompt drops everything from that prompt on; the prompt's text comes back into the input. An agent can't press keys while its own turn runs (`Esc` would interrupt it), so it schedules the keys in a background command and ends its turn.

## 📏 Rules that made it safe

- **Only in a window David gave** ("keyboard is yours"). Idle time is not a window (suss-troubleshoot-david-away, hard rule 3).
- **Every key is gated** through `~/.claude/skills/suss-troubleshoot-david-away/scripts/gate key iTerm2 -- '<keystroke>'`, and the script first checks that iTerm2's current session is the agent's own tab (`name of current session of current window` contains `<handle> (claude)`).
- **Look before you choose.** Round 1 opens the menu, screenshots it, and closes it with `Esc`. Round 2 moves to the target, screenshots, and closes again. Only round 3 selects. Each round is a `run_in_background` command, so its completion wakes the agent, which reads the screenshot (`screencapture -x`) and decides the next round.
- **The input must be empty**: double `Esc` on text clears it instead of opening the menu.

## 🗺️ What the menu looked like (Claude Code, 2026-10-26)

- "(current)" is selected at the bottom; `Up` moves to earlier prompts, one entry per prompt.
- Prompts David typed while a turn ran (mid-turn messages) are entries too. Stop-hook feedback is not.
- Each entry shows "No code changes" or "⚠ No code restore". With no tracked file edits after the point, only "Restore conversation", the summarize options and "Never mind" are offered.
- What the screenshots showed: round 1, the menu titled "Rewind · Restore the code and/or conversation to the point before…" with "(current)" selected under "↑ 12 more"; round 2, after 6 × `Up`, the target prompt selected with "↑ 6 more" and "↓ 6 more" around it, footer "Enter to continue · Esc to cancel". The images aren't committed: dotfiles is public and they show other agents' tabs.

- **The count drifts.** Every prompt David sends adds an entry, so the `Up` count to a fixed prompt grows by one per new prompt. Round 3 here landed one entry too late because David had sent a message after round 2. Background-task notifications are not entries. Re-verify the count right before the final round.
- `Return` on an entry opens a confirm screen: "Confirm you want to restore to the point before you sent this message", the prompt quoted, "The conversation will be forked. The code will be unchanged.", then `1. Restore conversation` (preselected), `2. Summarize from here`, `3. Summarize up to here`, `4. Never mind`. The number keys pick an option.
- Three `Esc` presses back out of the confirm screen and the list.

## ▶️ The scripts

- [scripts/rewind_probe.sh](scripts/rewind_probe.sh): waits 15 s for the turn to end, checks the tab, `Esc` `Esc`, screenshot, `Esc`.
- [scripts/rewind_verify.sh](scripts/rewind_verify.sh): same, then `Up` × 6, screenshot, `Esc` `Esc`.
- [scripts/rewind_actions.sh](scripts/rewind_actions.sh): same, then `Return`, screenshot of the confirm screen, `Esc` × 3.
- Key codes: `53` Esc, `126` Up, `36` Return.

## ❓ Not yet proven

The final `Return` on "Restore conversation" ran after this memo was last written. The rewound agent can't record it, so check its tab: its conversation should end right before the target prompt, with that prompt back in the input.

---
**Created by**: actors.owner.2 (2026-10-26)
