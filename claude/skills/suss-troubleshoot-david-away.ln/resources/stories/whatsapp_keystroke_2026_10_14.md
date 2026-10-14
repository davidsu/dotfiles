# Story: a gated test typed into WhatsApp (2026-10-14 00:13)

Source: `suss-tasks/dotfiles/floating_fzf_terminal/epic.md` (Notes 00:13), `dotfiles/teamup_focus_not_working/epic.md` (Incidents).

## What happened

- 00:11:28: the picker test read `HIDIdleTime` = 621 s, above its 600 s gate.
- It then asked the focus owner to pause its soak and waited 90 s. It did not re-read idle.
- 00:13: David was back, Chrome with WhatsApp in front. iTerm2 was not running (it had just crashed,
  see [iterm_crash_2026_10_14.md](iterm_crash_2026_10_14.md)), so no picker window opened.
- The test's keystrokes `l e a d` + Enter went to Chrome: WhatsApp sent "lead" to a colleague.

## How it was solved

- Reported on the channel at 00:14 with the screenshot; the lead relayed it; David deletes it himself.
- 00:15, lead: HARD STOP, nothing screen-touching for the rest of the night.
- The test script now re-checks idle right before opening, requires iTerm2 running, and sends a key only
  while iTerm2 is frontmost and the current session's profile is `Agent Picker` (`scripts/gate key`).

## What could be done differently

- Re-read idle at the moment of acting, not 90 s earlier.
- Check the target app is frontmost before **each** key, and never type while a browser or chat app is in front.
- Treat the preceding `Connection is invalid` as iTerm2 being dead, which it was.
