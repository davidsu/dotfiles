# Recipe: things got stuck

Symptom: a tool call hangs or errors, an app is gone, an agent does not answer.

## Is it an app crash? How to tell

- AppleScript `Connection is invalid (-609)` or `Can't get application "X" (-1728)` right after
  your call = **X died under your call**. Stop. No keys, no retry of that call.
- `$G crashes [MINUTES]` lists `.ips` reports newer than MINUTES in `~/Library/Logs/DiagnosticReports`.
  Read `exception` and the top frames of `faultingThread`: they name the call that killed it.
- Only a clean crash-report dir allows "David quit it" or "another agent did it".
- iTerm2 only: `pgrep iTermServer-` running while `pgrep -x iTerm2` is empty = the GUI died, the
  shells and every agent in them are alive.

## May I kill and relaunch the app?

- Relaunch, yes, always, for an app of David's that an agent broke: `$G relaunch APP` (it runs
  `open -a` only if the app is not running, and prints what it did). Then say on the channel:
  "relaunched X at HH:MM, cause: <crash frame or unknown>". David, 06:50: "quit and reopen. Why am I needed???"
- Kill, only what you started or what is provably wedged (a hung tick, your own poller). Killing
  an app David had open is a decision for him unless it blocks everyone and he announced a window.

## What survives, what to restore

- iTerm2: `open -a iTerm` reattaches every shell from `iTermServer`. Tab colors are lost: re-apply
  with `iterm_tab_style --tty <tty> --color <color>` from each agent's `/color`
  (`transcript_color` in the suss-teamup `session_colors.sh`). Titles return when each agent redraws.
- Claude sessions: `~/.claude/sessions/*.json` lists the live ones (`kill -0 <pid>`); a dead one with
  a transcript can be resumed by its owner's lead ([agent_lifecycle](~/.claude/skills/suss-teamup/resources/agent_lifecycle.md)).

## An agent does not answer

1. Its tab title: a busy glyph (◐ ◓ ◑ ◒) means mid-tool; wait.
2. `tail -c 2000 ~/.claude/projects/*/<session-id>.jsonl` shows what it was doing last.
3. Parked? `teamup-wake --list`; then `teamup-wake <handle> --role owner`.
4. Awake and silent: `teamup ask --to <handle>`; after 20 min write it in the task and route around it.

## Stories

- [iterm_crash_2026_10_14.md](../stories/iterm_crash_2026_10_14.md)
- [focus_poller_relaunch_2026_10_14.md](../stories/focus_poller_relaunch_2026_10_14.md)
