# Recipe: reminders, status, not getting stuck

## A reminder for David

- A launchd one-shot, not a cron in an agent session: agents die, launchd does not.
  `~/Library/LaunchAgents/com.davidsu.remind.<slug>.plist` with `StartCalendarInterval`, running a
  script under `~/.local/bin/`, stdout/err under `~/.local/state/suss-reminders/`. `launchctl load` it.
- It posts top-level in #suss-lead as David with `_agent:_` ([suss-communication](~/.claude/skills/suss-communication/SKILL.md)).

## Status

- Pull-based: no timed reports. David asks "what needs my attention"; keep that answer current in the
  task file. An explicit "remind me" is the one exception.

## Not getting stuck

- A blocker older than 20 min goes into the task file; then take the clunky path and move on.
- If it cannot be done, say so on the channel with the reason. Silence is the one unacceptable status.
