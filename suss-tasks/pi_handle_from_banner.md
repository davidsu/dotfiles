closed
# Give pi agents a teamup handle the user can see (/banner)

## Summary

A teamup handle had to equal the claude session name, but pi had no equivalent — pi peers
picked their own handle and answered to a name shown nowhere. pi's `/banner` is its
`/rename` (it sets the banner widget and the session name together), so the pi extension
now exports that name into the bash env and the script derives handles from it, on pi
exactly as it does from the session-name file on claude.

## 🔍 What pi actually offers

Probed with headless pi (`pi -p --no-session -e <extension>`), not assumed:

| Question                                    | Answer                                            |
|---------------------------------------------|---------------------------------------------------|
| Read the session name from an extension?    | `pi.getSessionName()` — real API                   |
| Unnamed session?                            | Returns undefined — no auto-derived noise          |
| What `/banner` does                         | Paints the banner **and** calls `setSessionName`   |
| Slash commands from argv?                   | Yes, and several argv messages run in order        |
| Terminal tab title                          | pi sets it, including the session name             |
| bash env freshness                          | `getShellEnv()` runs per command, from `process.env`|

Argv dispatch decided the design: a peer can name itself before it joins, which is
deterministic and focus-free, so pi needs none of claude's keystroke detour.

`/banner` is not built in — pi's built-in is `/name`, which sets the session name (pi puts
it in the footer and the terminal title) but paints no banner. `session-banner.ts` in this
repo registers `/banner`, which sets both, so it is the right target here.

## ✅ Fix

### 1. pi extension publishes identity

`publishSessionName()` exports `TEAMUP_NAME_COMMAND=/banner` plus `TEAMUP_SESSION_NAME`
(deleted when pi has no name, so nothing is invented). Called at `session_start` and every
`agent_start`, so a `/banner` typed mid-session reaches the channel on the next turn.

[publishSessionName](/pi/agent/extensions/teamup.ln.ts#L76)

### 2. Script derives from it, and can name the command

`chosen_session_name` prefers `$TEAMUP_SESSION_NAME` over the claude session-name file, so
`join` with no `--as` yields the banner text folded to a handle. `name_session_command`
(exposed as `teamup name-command`) answers "what does the USER type here" — `/rename` by
default, `/banner` when a harness says so — and is used by the missing-handle error and by
the hook's identity nudge.

[chosen_session_name](/claude/skills/suss-teamup.ln/scripts/teamup#L156) ·
[name_session_command](/claude/skills/suss-teamup.ln/scripts/teamup#L147) ·
[hook nudge](/claude/skills/suss-teamup.ln/scripts/teamup-hook#L84)

### 3. Spawned pi peers are named before they join

`teamup-spawn` runs `pi '/banner {handle}' '/skill:suss-teamup {subject}'`, so the assigned
handle is the session name *and* the banner by the time the skill joins. Only claude still
needs the keystroke detour, for `/color`.

[spawn launch strings](/claude/skills/suss-teamup.ln/scripts/teamup-spawn#L141)

## 🧪 Verification

- End-to-end in headless pi with both real extensions: `/banner probe-handle` then a bare
  `teamup join bannertest` → `joined 'bannertest' as 'probe-handle'`.
- Exported name with spaces folds correctly (`Pi Peer One` → `Pi-Peer-One`).
- Unnamed pi session with no `--as` fails with "ask the user to /banner it"; the same case
  on claude says "/rename". `teamup name-command` prints `/rename` / `/banner`.
- Hook drift nudge on pi: renames to a normal name produce the `teamup rename` line, and a
  channel-shaped name produces "ask the user to run '/banner {handle}'".
- All three spawn paths dry-run against a stubbed `term_spawn`; claude and codex launch
  strings unchanged.

## ⚠️ Regression caught during this work

Hoisting `color="$(parent_color)"` out of the injector call made a *no color* spawn abort:
under `set -eo pipefail` a failing command substitution in a standalone assignment kills
the script, where the same substitution inside a command argument had not. Guarded with
`|| true`, since having no color is the normal case.

suss-tasks/stop_pi_teamup_wait_thrashing.md#-fix-1 -> the pi thrashing fix this builds on

---
**Created by**: claude-code-session (2026-08-12)
