# Story: the focus poller opened windows while David watched, then relaunched a crashed iTerm2 (2026-10-13/14)

Source: `suss-tasks/dotfiles/teamup_focus_not_working/epic.md` (Root cause, Night part 2, Incidents, Follow-ups).

## What happened

- 21:38: David: the "max 3 min without a working agent on screen" poller did not work. Root cause: ~30
  pollers (one per owner reply via `teamup-slack`), Chrome preferred over any terminal, osascript errors swallowed.
- 23:11: a churn test opened ~150 fake windows while David sat watching without touching. `HIDIdleTime` ≥ 120 s
  cannot tell "watching" from "away".
- 00:16:18: iTerm2, down since its ~00:13 crash, came back up: a poller tick ran `tell application "iTerm2"`,
  which launches the app when it is not running. The relaunch hid the crash from everyone until 06:49.

## How it was solved

- One poller, claude iTerm tabs only, 55 s ticks, every error logged to `~/.local/state/suss-teamup/focus.log`
  (73573c8, e7d16d7).
- Never launch iTerm2: the poller checks `application "iTerm2" is running` first (3859343) and a stress check guards it (22fdbab).
- The poller was turned off for the rest of the night; windowed tests run only in a window David grants.

## What could be done differently

- Gate screen-touching tests on David's word, never on idle alone.
- Any automation that focuses or relaunches apps logs what it did and refuses to launch an app that is not running.
- When an app reappears by itself, look for a crash report before assuming it was never gone.
