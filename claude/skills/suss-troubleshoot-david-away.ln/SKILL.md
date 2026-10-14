---
name: suss-troubleshoot-david-away
description: >
  David is away/AFK and something on his Mac broke: an app vanished or crashed,
  iTerm quit unexpectedly, an agent is unresponsive, keystrokes went to the wrong
  app, an app answers "Connection is invalid" / "Can't get application". Also load
  BEFORE any screen action (open a window, send a synthetic keystroke, change
  focus, record). Decision table: symptom → first check → safe action → when to
  wait for David. Covers the idle gate and how it fails, the per-key frontmost
  check, crash-report triage, relaunching, config values vs. the installed app
  version, reminders and status while he is away, where agents' state lives.
---

# Troubleshooting and screen work while David is away

Written after the night of 2026-10-13/14 (tasks `dotfiles/floating_fzf_terminal`,
`dotfiles/teamup_focus_not_working`): a gated test typed into David's WhatsApp, a profile
value crashed iTerm2 twice, a poller relaunched iTerm2 and hid the crash. Every rule below
is one of those failures, inverted.

## Decision table

| Symptom | First check | Safe action (do it, say it) | Wait for David when |
|---|---|---|---|
| App vanished; `Connection is invalid (-609)` / `Can't get application (-1728)` right after your call | `$G crashes`, read the `.ips` exception + top frames (§3) | `$G relaunch APP`, post "relaunched X at HH:MM" + cause on the channel | never for the relaunch; before retrying the call that killed it |
| iTerm2 quit | same as above; `pgrep iTermServer` (sessions survive) | `$G relaunch iTerm2`; restore tab colors with `iterm_tab_style` (§3) | never ("quit and reopen. Why am I needed???", 06:50) |
| An agent is unresponsive | its tab: busy glyph? its transcript's last line (§9); `teamup-wake --list` | `teamup-wake <handle>` if parked; else `teamup ask --to <handle>` | the agent is mid-work and only David's input unblocks it |
| Keystrokes went to the wrong app | screenshot now; what was frontmost (§2) | report within a minute: screenshot path, text, recipient (§6); stop all keys | always, before any further key |
| You need a screen action (window, key, focus) | David announced a window ("I'm afk", "go, hands off")? `$G idle` right before; `$G front` per key (§1-2) | run it gated via `$G key`; announce ON/OFF to other owners | no announced window: idle alone is not "away" |
| A config value / enum for an installed app | the installed version's source or validation (§4) | first use against a throwaway with `$G crashes 1` watched | the first use is on the window David works in |
| David wants to be reminded | `ls ~/Library/LaunchAgents/com.davidsu.remind.*` (§7) | a launchd one-shot that posts top-level in #suss-lead | never |
| Blocked > 20 min | the task file (§8) | write the blocker in the task, take the clunky path | it genuinely cannot be done: say so, with the reason |

`scripts/gate` is the mechanism; use it instead of re-deriving the checks:

```
G=~/.claude/skills/suss-troubleshoot-david-away/scripts/gate
$G idle [MIN_SECONDS]            # exit 0 when HIDIdleTime ≥ MIN (default 600); prints the value
$G front APP [PROFILE]           # exit 0 when APP is frontmost (and, for iTerm2, the current session's profile is PROFILE)
$G key APP [PROFILE] -- 'keystroke "x"'   # `front` check, THEN the System Events keystroke; nothing is sent otherwise
$G crashes [MINUTES]             # crash reports (.ips) newer than MINUTES (default 30) in ~/Library/Logs/DiagnosticReports
$G relaunch APP                  # relaunch APP if it is not running, and say so loudly (exit 0 = running)
```

## 1. The idle gate is a moment, not a state

- `HIDIdleTime` says nothing about the next second. Re-read it **immediately before the first
  screen action**, not before a handshake, a `teamup wait`, or a `sleep`. (00:11 idle 621 s →
  90 s handshake → 00:13 David back → keys went to Chrome.)
- Your own synthetic keystrokes and clicks reset `HIDIdleTime`. Announce runs to other owners
  (`fzf tests ON` / `OFF` on their channel) so their gates do not read your input as David's.
- Threshold: David's lead sets it (600 s at night; 60 s when David says "I'm AFK" in the channel).
  No idle gate replaces his word for anything that types into an app.

## 2. Every synthetic key is gated on its own

- Before **each** key: the target app is frontmost **and** the target window exists (for iTerm,
  the current session's profile name). `$G key` does exactly that. One check at the start is
  how "lead" + Enter reached WhatsApp.
- Never send a key while a browser, Slack, WhatsApp or Mail is frontmost. Abort, do not switch
  apps to "fix" it.
- Prefer input that cannot miss: write to the tty (`iterm_tab_style`), AppleScript `write text`
  to a known session, the tool's own CLI. A System Events keystroke is the last resort.

## 3. An app that vanishes is a crash until proven otherwise

- AppleScript `Connection is invalid (-609)` or `Can't get application "X" (-1728)` right after
  your call = **X died under your call**. Stop. Do not send keys, do not retry the call.
- Run `$G crashes` and read the top frames of the `.ips` (`exception`, `faultingThread`).
  Attribute to David only after the crash-report dir is clean.
- Relaunching his app is risk-free work: `$G relaunch X`, then say "relaunched X at HH:MM" on
  the channel (David, 06:50: "quit and reopen. Why am I needed???"). iTerm2 restores the shells
  from `iTermServer`; tab colors are lost, re-apply with `iterm_tab_style --tty … --color …`
  from each agent's `/color` (`transcript_color` in `session_colors.sh`); titles return when
  each agent redraws.
- An app that comes back by itself (another agent's poller did `tell application`) hides the
  crash. A poller must guard with `if application "X" is running` and log any relaunch.

## 4. Config values come from the installed version

- A key or enum copied from a project's `master` source must be checked against the **installed**
  version's source (`gh api …/contents/PATH?ref=vX.Y.Z`) or the app's own validation. iTerm
  3.7.3 asserted on `Window Type: 19` (master-only) and aborted.
- First use of any new profile / rule / plist: with the crash-report dir watched (`$G crashes 1`
  right after), and never against the window David is working in.

## 5. Before the first real run, exercise the failure path headlessly

- `tmux -L test -f /dev/null new-session -d …` + `send-keys` drives a TUI with no window and no
  HID input. Test Esc / empty selection / abort there first: the picker's Esc path exec'd the
  legacy dialog, found only on the real screen.

## 6. Reporting

- Something went to a human (a message, a keystroke in a chat): say it on the channel within a
  minute, with the screenshot path, what it said and to whom; David deletes/edits himself.
- Write the incident, the cause and the fix into the suss-task the same hour.

## 7. Reminders and status while he is away

- A reminder for David is a launchd one-shot (`~/Library/LaunchAgents/com.davidsu.remind.<slug>.plist`,
  `StartCalendarInterval`, a script under `~/.local/bin/`), not a cron in an agent session: agents
  die, launchd does not. It posts top-level in #suss-lead as David with `_agent:_`
  ([suss-communication](../suss-communication/SKILL.md)).
- Status is pull-based: no timed reports. David asks "what needs my attention"; keep that answer
  ready in the task. An explicit "remind me" is the one exception.

## 8. Don't get stuck

- A blocker older than 20 min goes into the task file, then take the clunky path and move on.
- If it cannot be done, say so on the channel with the reason. Silence is the one unacceptable
  status.

## 9. Where things live

| What | Where |
|---|---|
| An agent's transcript | `~/.claude/projects/*/<session-id>.jsonl` (`rg --no-config`: files > 10 MB are skipped by the rg config) |
| A teamup channel | `/tmp/suss-teamup/<subject>/channel.tsv`; its Slack thread url `~/.local/state/suss-teamup/slack/<subject>.url` |
| Parked (asleep) agents | `~/.local/state/suss-teamup/parked.tsv`; `teamup-wake <handle> --role owner` ([agent_lifecycle](../suss-teamup/resources/agent_lifecycle.md)) |
| The focus poller | `teamup-focus on [--skip HANDLE] \| off \| status`; log `~/.local/state/suss-teamup/focus.log`; it relaunched iTerm2 once and now guards with `application is running` (task `dotfiles/teamup_focus_not_working`) |
| Slack bridges | `teamup-slack off/on <subject>` (`off` also kills your `wait`) ([slack_mirror](../suss-teamup/resources/slack_mirror.md)) |
| Crash reports | `~/Library/Logs/DiagnosticReports/*.ips` (`$G crashes`) |
