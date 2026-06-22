---
name: suss-teamup
description: >
  Let multiple agents coordinate over a shared file-based channel. Invoke with
  /suss-teamup {subject} to join a channel, announce what you're doing and where
  (pwd/worktree), and discover other agents working nearby so you can align —
  share a plan, avoid implementing the same thing twice, or keep two worktrees
  in lockstep for clean merges. /suss-teamup {subject} disconnect leaves one
  channel; /suss-teamup disconnect all leaves every channel.
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Team Up — agent-to-agent coordination

A channel is just two cheap things on disk under `/tmp/suss-teamup/{subject}/`:
an append-only message log and a presence roster. Agents talk by appending
lines and reading only what's new since they last looked — no daemon, no deps,
no context blowup.

**The script is the whole mechanism.** Always call it by absolute path:

```
~/.claude/skills/suss-teamup/scripts/teamup <cmd> ...
```

Run `teamup` with no args (or a bad one) to see usage.

## Parsing the invocation

- `/suss-teamup {subject}` → **join** channel `{subject}`.
- `/suss-teamup {subject} disconnect` → **leave** `{subject}`.
- `/suss-teamup disconnect all` → **leave every** channel you're on.

If no subject is given on a join, ask the user for one — don't guess.

## Your handle

On join, pick a short, stable **handle** that identifies *you* to peers — use
your worktree/branch basename or your role (e.g. `auth-wt`, `reviewer`,
`api-refactor`). Remember it: you pass `--as {handle}` on **every** call this
session. It keys your read-cursor and your roster entry.

## 1. Join — ping and orient

```
teamup join {subject} --as {handle} --pwd "$PWD" --doing "<one line: what you're working on>"
```

This announces you (a `ping`), registers your presence, prints the current
roster, and shows recent history. Read the roster: **is anyone else here?**

- **Alone on the channel** → you can't team up yet. Tell the user you've joined
  and are waiting, then either continue your own work and `recv` at checkpoints,
  or background-wait to be woken (see §4). Don't block idle for long.
- **Someone else is here** → go to §2 and huddle.

## 2. Huddle — align before you build (blocking)

Once ≥1 peer is present, describe concretely: **what** you're implementing,
**which pwd/worktree** you're in, and the **shape** of your intended solution
(file, function signature, data shape). Then block for replies:

```
teamup say  {subject} --as {handle} -- "<your message; put free text after -->"
teamup wait {subject} --as {handle} --timeout 110   # blocks until a peer speaks
```

Keep `--timeout` ≤ 110s so it fits the default Bash budget; for a longer hold,
raise the Bash tool timeout to match. Loop say→wait until you've reached an
agreement. Look for the three coordination cases:

- **חפיפה / overlap** — you're on different tasks that touch the same code.
  Agree who owns the shared piece so you don't collide.
- **Same worktree** — split the work, claim files explicitly ("I'll take
  `X`, you take `Y`"), and stay out of each other's files.
- **Different worktrees, same change** — instead of implementing the same
  thing two different ways, **agree on one shared solution** (identical
  signatures, names, file layout) and each apply it in your own worktree. This
  is the high-value case: it makes the later merge trivial.

Confirm the agreement out loud on the channel before anyone starts coding, so
it's on the record for peers joining later.

## 3. Implement — check in at checkpoints (non-blocking)

While heads-down writing code, don't block. At natural breakpoints (finished a
step, about to touch a shared file, hit a blocker) do a quick:

```
teamup recv {subject} --as {handle}   # prints only messages from others since last read
```

If a peer asks something or your plan changed, `say` an update. When you finish
the shared piece, announce it so peers can pull/rebase.

## 4. Background wait — get woken while idle

When you'd otherwise be waiting (peer is still working, nothing to do), launch a
blocking wait as a **background** Bash command with **`--timeout 0`** (waits
indefinitely):

```
teamup wait {subject} --as {handle} --timeout 0
```

Run it with `run_in_background: true`. With `--timeout 0` the watcher stays
armed across your whole work-turn instead of expiring after ~110s, so it's still
listening when a peer finally speaks. When one does, it exits and the harness
re-invokes you with the message — a poor-agent's interrupt. **Re-arm it after you
respond** if you're still idle; that re-arm is on you.

> ⚠️ This wake is best-effort, not a true interrupt. A background command can
> only re-invoke you **between** turns — while you're heads-down in a turn you're
> unreachable. So a long-armed `wait` is not a substitute for a deliberate `recv`
> at every checkpoint (§3): always `recv` when you finish a step or are about to
> touch shared code. If agents still drift out of the channel, the durable fix is
> harness hooks (see the KNOWN ISSUE note atop `scripts/teamup`).

## 5. Disconnect

Always leave when you're done so the roster stays honest:

```
teamup leave {subject} --as {handle}   # one channel
teamup leave --all     --as {handle}   # every channel you're on
```

Leaving posts a `bye` so peers know you're gone.

## Etiquette

- One line per message; lead with intent (`overlap on tokenValidator?`,
  `claiming src/auth/*`, `done: pushed validator to wt-a`).
- Announce file claims **before** editing shared code; release them when done.
- Re-state agreements when a new peer joins — `peek` history is there, but a
  one-line recap is kinder.
- This is coordination, not a chat. If there's nothing to coordinate, say so
  and get back to work.

## Reference

| command | does |
|---|---|
| `join {subject} --as H [--pwd P] [--doing T]` | announce + register + show roster/history |
| `say {subject} --as H -- <text>` | post a message (alias: `send`) |
| `recv {subject} --as H` | print peers' messages since last read (non-blocking) |
| `wait {subject} --as H [--timeout S]` | block until a peer speaks or timeout (`--timeout 0` = forever; use for background idle waits) |
| `roster {subject}` | who's on the channel |
| `peek {subject} [--last N]` | recent history (default 20) |
| `leave {subject} --as H` / `leave --all --as H` | disconnect |
| `channels` | list active subjects |

State lives under `$SUSS_TEAMUP_DIR` (default `/tmp/suss-teamup`). Cleared on
reboot; that's fine — channels are ephemeral per work session.
