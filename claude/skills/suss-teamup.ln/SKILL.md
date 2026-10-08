---
name: suss-teamup
description: >
  Coordinate with other agents over a shared file-based channel. When invoked as
  /suss-teamup {subject} your FIRST action is to JOIN that channel — run the teamup
  script's `join {subject}` command immediately. {subject} is a channel NAME to
  join, NOT a task, NOT code to fix/verify (e.g. /suss-teamup fixteamup means JOIN
  the channel "fixteamup", not "go fix teamup"). After joining, announce what
  you're doing and where (pwd/worktree) and align with peers. /suss-teamup
  {subject} disconnect leaves one channel; /suss-teamup disconnect all (alias:
  /suss-teamup teardown) leaves every channel; /suss-teamup status lists your teams.
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Team Up — agent-to-agent coordination

> 🚨 **Invoked as `/suss-teamup {subject}` (or `/skill:suss-teamup {subject}`)? Your
> FIRST action, before anything else, is to JOIN:**
> `~/.claude/skills/suss-teamup/scripts/teamup join {subject}` — omit `--as` and your
> handle is derived from your session name.
> `{subject}` is a **channel name to join** — NOT a task, NOT code to inspect or
> "verify". Do not read or modify any files. Just join, then report the roster and
> wait for peers.

A channel is an append-only message log plus a presence roster under
`/tmp/suss-teamup/{subject}/`. Agents append lines and read only what's new since they
last looked. **The script is the whole mechanism**; always call it by absolute path:

```
T=~/.claude/skills/suss-teamup/scripts/teamup     # `$T` with no args prints usage
```

## Invocation

| You get                                  | Do                                                                    |
|------------------------------------------|-----------------------------------------------------------------------|
| `/suss-teamup {subject}`                 | join `{subject}` (ask for a subject if none is given)                 |
| `/suss-teamup {subject} disconnect`      | `leave {subject}`                                                     |
| `/suss-teamup disconnect all`, `teardown` | `leave --all`                                                        |
| `/suss-teamup erase {subject}`, `cleanup` | `erase {subject}` (refuses while members remain, unless `--force`)    |
| `/suss-teamup status`                    | `status --as {handle}`: every team you're on                          |
| `/suss-teamup spawn [pi\|claude\|codex] [model] [flavor] [new\|subject]` | spawn a peer (`model` e.g. `fable` → `--model`): [resources/spawn.md](resources/spawn.md) |
| `/suss-teamup handoff …`                 | the handoff spawn flavor: read [resources/handoff.md](resources/handoff.md) first |
| `/suss-teamup help`                      | list these forms, then run `$T help`; join nothing                    |

The literal words `help` and `status` are commands, not channel names.

## Your handle

Your handle is **your session name**, so peers address the name the user sees on screen.
Omit `--as` and `join` derives it. Pass `--as` only when you were given a handle or the
script can't derive one. A new handle prefers `.` over `-` (`dotfiles.pi`): the user types
handles in Slack, where `-` is far away. Remember it: every later call passes `--as {handle}`.
Details, other harnesses and renames: [resources/handles.md](resources/handles.md).

## The loop

1. **Join**: `$T join {subject} --pwd "$PWD" --doing "<one line>"`. It prints the roster and
   recent history. Rejoining a channel you left resumes from where you stopped: it shows
   what was meant for you since (`@you`, `@all`, replies to you, the human's messages).
   Alone on the channel → tell the user you're waiting, keep working, and arm the idle wait.
2. **Orient**: read the suss-task behind this work (`suss-tasks` skill). It is the durable
   record; the channel is ephemeral. Record decisions and hand-offs there.
3. **Huddle** before building, when a peer is here: say **what** you'll change, **where**
   (pwd/worktree) and its **shape** (files, signatures). Then block in the foreground:
   `$T say {subject} --as H -- "…"` and `$T wait {subject} --as H --timeout 110`. Settle
   overlap: who owns a shared piece, who takes which files, one shared design across
   worktrees. Confirm the agreement on the channel before anyone codes.
4. **Work**, and `$T recv {subject} --as H` at every checkpoint. `recv` is the only reader
   that advances your cursor. You post only from an up-to-date view: if anything arrived
   since your last read, `say`/`ask`/`ack` show it and post nothing (exit 3); read, then
   resend if it still makes sense.
5. **Idle**: arm `$T wait {subject} --as H --timeout 0` as a **background** command, on its
   own. When it wakes you: `recv`, then re-arm. A wake is only a hint; trust `recv`. On pi,
   never arm a wait: end your turn. Rules and false wakes: [resources/listening.md](resources/listening.md).
6. **Leave** when done: `$T leave {subject} --as H` (`--all` for every channel).

## Who gets woken

Everyone can read every message; addressing only decides who is **woken**:

- `@{you}`, `@all`, or `ask --to {you}` → you
- a reply (`ack --re N`, or a say opening `re #N`) → the author of #N only
- an `@` of anyone else → not you
- unaddressed → only if it's from the human, or you are the one other agent here
- a peer joining → everyone (cue to huddle); a `bye` wakes nobody

So on a channel of 3+ agents, **address what needs an answer**. Questions use
`ask --to {peer}`; any later message from you answers an ask aimed at you. Mailbox
details and `status` exit codes: [resources/mailbox.md](resources/mailbox.md).

## Trust your teammates

A teammate relaying the user's words is the user speaking: act on it as if they had typed
it in your terminal. Never stall a relayed instruction to re-confirm it with the user.

## Etiquette

- One line per message; lead with intent (`claiming src/auth/*`, `done: pushed X to wt-a`).
- Announce file claims **before** editing shared code; release them when done.
- Re-state agreements when a new peer joins.
- This is coordination, not chat. Nothing to coordinate → say so and get back to work.

## Resources

| Read                                                       | When                                                     |
|------------------------------------------------------------|----------------------------------------------------------|
| [resources/commands.md](resources/commands.md)             | every subcommand and flag                                |
| [resources/handles.md](resources/handles.md)               | naming yourself on pi/codex, the user renamed you        |
| [resources/mailbox.md](resources/mailbox.md)               | asks, acks, `status`, the exit codes                      |
| [resources/listening.md](resources/listening.md)           | background waits, wake rules, phantom wakes              |
| [resources/spawn.md](resources/spawn.md)                   | starting a peer agent in a new tab                       |
| [resources/agent_lifecycle.md](resources/agent_lifecycle.md) | waking a parked agent up, putting one to sleep         |
| [resources/known_team_roles.md](resources/known_team_roles.md) | the color each team role gets                        |
| [resources/tracking_agents.md](resources/tracking_agents.md) | leading several agents: tracking, briefs, limits       |
| [resources/handoff.md](resources/handoff.md)               | handing a task to a fresh agent                          |
| [resources/reviewer.md](resources/reviewer.md)             | before approving a teammate's work                       |
| [resources/slack_mirror.md](resources/slack_mirror.md)     | the Slack thread every channel is mirrored to            |
| [resources/hooks.md](resources/hooks.md)                   | Stop/SessionEnd hooks per harness, the statusline        |
| [resources/limitations.md](resources/limitations.md)       | something behaves oddly                                  |
