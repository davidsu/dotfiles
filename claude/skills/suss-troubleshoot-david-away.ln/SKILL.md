---
name: suss-troubleshoot-david-away
description: >
  Rules for an agent that must touch David's Mac screen (open a window, send a
  synthetic keystroke, change focus, record) or finds one of his apps gone while
  he is away. Load BEFORE any such action and when an app answers "Connection is
  invalid" / "Can't get application". Covers the idle gate and how it fails, the
  per-key frontmost check, crash-report triage, relaunching, config values vs.
  the installed app version, and ON/OFF coordination with other owners.
---

# Troubleshooting and screen work while David is away

Written after the night of 2026-10-13/14 (task `dotfiles/floating_fzf_terminal`): a gated
test typed into David's WhatsApp, and a profile value crashed iTerm2 twice. Every rule
below is one of those failures, inverted.

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
