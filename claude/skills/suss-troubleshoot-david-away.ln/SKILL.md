---
name: suss-troubleshoot-david-away
description: >
  David is away/AFK and something on his Mac broke: an app vanished or crashed,
  iTerm quit unexpectedly, an agent is unresponsive, keystrokes went to the wrong
  app, an app answers "Connection is invalid" / "Can't get application". Also load
  BEFORE any screen action (open a window, send a synthetic keystroke, change
  focus, record). Recipes (symptom-first: things got stuck, screen action, config
  for the installed app, reminders and status) and stories (what happened the
  night of 2026-10-13/14, how it was solved, what to do differently).
---

# Troubleshooting and screen work while David is away

Recipes are generic and symptom-first; stories are one incident each, facts only. Recipes link
the stories they came from. Learned something: fix the recipe, add a story.

## Decision table

| Symptom | First check | Safe action (do it, say it) | Wait for David when | Recipe |
|---|---|---|---|---|
| App vanished; `Connection is invalid (-609)` / `Can't get application (-1728)` right after your call | `$G crashes`; read the `.ips` exception + top frames | `$G relaunch APP`; post "relaunched X at HH:MM" + cause | never for the relaunch; before retrying the call that killed it | [things_got_stuck](resources/recipes/things_got_stuck.md) |
| iTerm2 quit | same; `pgrep iTermServer` (shells survive) | `$G relaunch iTerm2`; restore tab colors | never ("quit and reopen. Why am I needed???", 06:50) | [things_got_stuck](resources/recipes/things_got_stuck.md) |
| An agent is unresponsive | its tab's busy glyph; its transcript's last line; `teamup-wake --list` | `teamup-wake <handle>` if parked, else `teamup ask --to <handle>` | it is mid-work and only David's input unblocks it | [things_got_stuck](resources/recipes/things_got_stuck.md) |
| Keystrokes went to the wrong app | screenshot now; what was frontmost | report within a minute: screenshot path, text, recipient; stop all keys | always, before any further key | [screen_action](resources/recipes/screen_action.md) |
| You need a screen action (window, key, focus) | did David announce a window ("I'm afk", "go, hands off")? `$G idle` right before; `$G front` per key | run it via `$G key`; announce ON/OFF to other owners | no announced window: idle alone is not "away" | [screen_action](resources/recipes/screen_action.md) |
| A config value / enum for an installed app | the installed version's source or validation | first use against a throwaway with `$G crashes 1` watched | the first use is on the window David works in | [config_for_installed_app](resources/recipes/config_for_installed_app.md) |
| David wants to be reminded | `ls ~/Library/LaunchAgents/com.davidsu.remind.*` | a launchd one-shot that posts top-level in #suss-lead | never | [reminders_and_status](resources/recipes/reminders_and_status.md) |
| Blocked > 20 min | the task file | write the blocker in the task, take the clunky path | it cannot be done: say so, with the reason | [reminders_and_status](resources/recipes/reminders_and_status.md) |

## Hard rules

1. An app that vanishes is a crash until the crash-report dir says otherwise. Attribute to David last.
2. Relaunching an app an agent broke is risk-free work: do it, then say it.
3. Idle time is not "away". Screen actions happen only in a window David announced.
4. Every synthetic key is gated on its own, immediately before it: target app frontmost, target window present. Never over a browser, Slack, WhatsApp or Mail.
5. Config values come from the installed version, never from a project's `master`.
6. Anything that relaunches or focuses apps automatically logs loudly and guards with `application is running`.
7. Something reached a human: say it on the channel within a minute, with the screenshot path.
8. Status is pull-based; reminders are launchd one-shots; a blocker > 20 min goes into the task and you move on.

## Recipes

| Recipe | Covers | File |
|---|---|---|
| Things got stuck | Is it a crash? how to tell; may I kill and relaunch; what survives; restoring tabs; an agent that does not answer | [things_got_stuck.md](resources/recipes/things_got_stuck.md) |
| Screen action | The idle gate and how it fails, the per-key frontmost check, ON/OFF with other owners, input that cannot miss, headless failure paths, reporting a misfire | [screen_action.md](resources/recipes/screen_action.md) |
| Config for the installed app | Validating keys and enums against the installed version; first use of a new profile | [config_for_installed_app.md](resources/recipes/config_for_installed_app.md) |
| Reminders and status | launchd one-shots, pull-based status, not getting stuck | [reminders_and_status.md](resources/recipes/reminders_and_status.md) |

## Stories

| Story | One line | File |
|---|---|---|
| iTerm2 crash, 2026-10-14 | A profile `Window Type` from iTerm master crashed iTerm2 3.7.3 twice; the shells survived on iTermServer | [iterm_crash_2026_10_14.md](resources/stories/iterm_crash_2026_10_14.md) |
| WhatsApp keystroke, 2026-10-14 | A gated screen test checked idle once, waited 90 s, and typed "lead" + Enter into WhatsApp | [whatsapp_keystroke_2026_10_14.md](resources/stories/whatsapp_keystroke_2026_10_14.md) |
| Focus poller relaunch, 2026-10-13/14 | The focus poller opened ~150 windows while David watched, then relaunched a crashed iTerm2 and hid the crash | [focus_poller_relaunch_2026_10_14.md](resources/stories/focus_poller_relaunch_2026_10_14.md) |
| Slack session rotation, 2026-10-14 | Slack rotated the web session at 07:33; every token-based bridge on both machines died silently; rebuilt on the claude.ai connector | [slack_session_rotation_2026_10_14.md](resources/stories/slack_session_rotation_2026_10_14.md) |

## The gate script

`scripts/gate` is the mechanism; use it instead of re-deriving the checks:

```
G=~/.claude/skills/suss-troubleshoot-david-away/scripts/gate
$G idle [MIN_SECONDS]            # exit 0 when HIDIdleTime ≥ MIN (default 600); prints the value
$G front APP [PROFILE]           # exit 0 when APP is frontmost (and, for iTerm2, the current session's profile is PROFILE)
$G key APP [PROFILE] -- 'keystroke "x"'   # `front` check, THEN the System Events keystroke; nothing is sent otherwise
$G crashes [MINUTES]             # crash reports (.ips) newer than MINUTES (default 30) in ~/Library/Logs/DiagnosticReports
$G relaunch APP                  # relaunch APP if it is not running, and say so loudly (exit 0 = running)
```

## Where things live

| What | Where |
|---|---|
| An agent's transcript | `~/.claude/projects/*/<session-id>.jsonl` (`rg --no-config`: files > 10 MB are skipped by the rg config) |
| A teamup channel | `/tmp/suss-teamup/<subject>/channel.tsv`; its Slack thread url `~/.local/state/suss-teamup/slack/<subject>.url` |
| Parked (asleep) agents | `~/.local/state/suss-teamup/parked.tsv`; `teamup-wake <handle> --role owner` ([agent_lifecycle](~/.claude/skills/suss-teamup/resources/agent_lifecycle.md)) |
| The focus poller | `teamup-focus on [--skip HANDLE] \| off \| status`; log `~/.local/state/suss-teamup/focus.log` |
| Slack bridges | `teamup-slack off/on <subject>` (`off` also kills your `wait`) ([slack_mirror](~/.claude/skills/suss-teamup/resources/slack_mirror.md)) |
| Crash reports | `~/Library/Logs/DiagnosticReports/*.ips` (`$G crashes`) |
| Reminders | `~/Library/LaunchAgents/com.davidsu.remind.<slug>.plist`, scripts under `~/.local/bin/` |
