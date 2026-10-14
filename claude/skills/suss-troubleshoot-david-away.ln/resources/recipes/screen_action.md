# Recipe: a screen action (window, synthetic key, focus, recording)

## Before anything

- David announced a window ("I'm afk", "go, hands off") or your lead relays his GO. No announcement,
  no screen action. Idle alone is not "away": he may be watching (2026-10-13 23:11, ~150 windows
  opened while he watched).
- Announce `<thing> tests ON` to the other owners on their channel; `OFF` when done. Your own
  synthetic input resets `HIDIdleTime` and fools their gates.

## The idle gate is a moment, not a state

- `$G idle [MIN]` **immediately before the first screen action**, not before a handshake, a
  `teamup wait` or a `sleep`. Threshold from the lead: 600 s at night, 60 s after "I'm AFK".

## Every synthetic key is gated on its own

- `$G key APP [PROFILE] -- 'keystroke "x"'`: checks that APP is frontmost (for iTerm2, that the
  current session's profile is PROFILE), then sends. Nothing is sent otherwise. One check at the
  start of a sequence is how "lead" + Enter reached WhatsApp.
- A browser, Slack, WhatsApp or Mail in front: abort. Do not switch apps to "fix" it.
- Prefer input that cannot miss: write to the tty (`iterm_tab_style`), AppleScript `write text` to a
  known session, the tool's own CLI. A System Events keystroke is the last resort.

## Before the first real run

- Drive the TUI headlessly: `tmux -L test -f /dev/null new-session -d …` + `send-keys`. Exercise Esc,
  empty selection, abort there; the picker's Esc path exec'd a legacy dialog found only on screen.
- First window of a new profile: against a throwaway, `$G crashes 1` right after
  ([config_for_installed_app](config_for_installed_app.md)).

## When it misfires

- Something reached a human: say it on the channel within a minute: screenshot path, the text, the
  recipient. David deletes or edits it himself. Then stop every key for the night unless he says otherwise.
- Write the incident, cause and fix into the suss-task the same hour.

## Stories

- [whatsapp_keystroke_2026_10_14.md](../stories/whatsapp_keystroke_2026_10_14.md)
- [focus_poller_relaunch_2026_10_14.md](../stories/focus_poller_relaunch_2026_10_14.md)
