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
> `~/.claude/skills/suss-teamup/scripts/teamup join {subject} --as {handle}`.
> `{subject}` is a **channel name to join** — NOT a task, NOT code to inspect or
> "verify". Do not read or modify any files. Just join, then report the roster and
> wait for peers. (The `disconnect` / `status` variants are below.)

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
- `/suss-teamup teardown` → **alias for `disconnect all`** — leave every channel
  you're on (runs `teamup leave --all --as {handle}`).
- `/suss-teamup status` → **overview**: run `teamup status --as {handle}` (no
  subject) to list every team you're on + its member count. Treat the literal
  word `status` as this command, not a channel named "status".

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

`recv` leads with a machine-readable summary line, then the new messages:

```
summary: unread=2 asks_for_me=1 from=alice
  #7 [09:12:03] alice (ask) @you can you take the parser?
  #8 [09:12:30] alice (say) fyi I pushed a stub
```

Every message carries a stable `#seq` id (its line number). If a peer asks
something or your plan changed, `say` an update. When you finish the shared
piece, announce it so peers can pull/rebase.

## 3a. Asks, acks, and status — the mailbox protocol

This is a dumb, readable mailbox any agent (Codex / Gemini / Claude) can follow.

- **Ask a question that needs an answer** — `ask` (not `say`), and target the
  person with `--to` so it shows up as *theirs*:

  ```
  teamup ask {subject} --as {handle} --to {peer} -- "review PR #5 before I rebase?"
  ```

- **Clear an ask** — you don't need a special command: **any** later message
  from you (a `say`, your next `ask`, anything) counts as answering it. `ack` is
  just a tidy way to do it with an explicit reference, defaulting to the latest
  peer message:

  ```
  teamup ack {subject} --as {handle} --re 7 -- "done, take a look"
  ```

- **Check standing without consuming anything** — `status` prints the same
  summary line and sets a machine-usable exit code, **without moving your read
  cursor** (so it's safe to call from a hook):

  | exit | meaning |
  |---|---|
  | `0` | clean — nothing unread, nothing waiting on you |
  | `1` | unread messages, but none are asks aimed at you |
  | `2` | a peer is waiting on an answer from you (`asks_for_me > 0`) |

  ```
  teamup status {subject} --as {handle}   # exit 2 = someone needs you
  ```

  `status` is the piece a harness can wire a `Stop` hook to: block the stop
  while it exits non-zero so an agent can't walk away from an open question.
  An ask aimed at you stays "for you" only until your next message — answer in
  prose and it clears; there is no bookkeeping to keep in sync.

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
> touch shared code. The durable fix for drift is harness lifecycle hooks — see
> §6.

## 5. Disconnect

Always leave when you're done so the roster stays honest:

```
teamup leave {subject} --as {handle}   # one channel
teamup leave --all     --as {handle}   # every channel you're on
```

Leaving posts a `bye` so peers know you're gone. `/suss-teamup teardown` is an
alias for `/suss-teamup disconnect all` — both run `teamup leave --all`.

## 6. Stay on the channel automatically — lifecycle hooks

`recv` at checkpoints (§3) and a background `wait` (§4) are best-effort: an agent
that goes heads-down still forgets. The durable fix is a harness **Stop hook** so
an agent literally cannot end its turn while peer messages sit unread.
`scripts/teamup-hook` provides this, harness-neutrally:

- `join`/`leave` persist a `cwd → (subject, handle, session_guid)` map in
  `$SUSS_TEAMUP_DIR/.sessions.tsv`. The **session GUID** is the key — it's
  collision-free even when several agents share a cwd (the original "two agents in
  one dir cross-deliver each other's mail" bug). `join` reads the GUID from
  `$TEAMUP_SESSION` (set by a harness wrapper, e.g. the pi extension) or
  `$CLAUDE_CODE_SESSION_ID` (native to claude-code); if neither is set the row's
  GUID is empty and the hook falls back to cwd matching.
- `teamup-hook stop` reads `.session_id` (and `.cwd`) from the hook event JSON on
  stdin, finds this session's channels (by GUID, else cwd), and **exits 2 to block
  the stop** while any has unread messages — forcing a `recv` first. It blocks on
  *unread only* (which `recv` always clears), so it can't loop; it fails open
  (exit 0) on any missing input or tool error.
- `teamup-hook session-end` auto-`leave`s this session's channels so rosters stay honest.
- `join` also **refuses a handle already held by a different session** (cursor
  files are keyed by handle, so two live sessions sharing one would race it).

**claude-code wiring** (`~/.claude/settings.json`):

```json
"hooks": {
  "Stop":       [{ "hooks": [{ "type": "command", "command": "~/.claude/skills/suss-teamup/scripts/teamup-hook stop",        "timeout": 10 }] }],
  "SessionEnd": [{ "hooks": [{ "type": "command", "command": "~/.claude/skills/suss-teamup/scripts/teamup-hook session-end", "timeout": 10 }] }]
}
```

**pi (pi-coding-agent):** the extension `~/.pi/agent/extensions/teamup.ts` (from
`pi/agent/extensions/teamup.ln.ts`) wires this in. At `session_start` it sets
`process.env.TEAMUP_SESSION = sessionManager.getSessionId()` so the bash `join`
inherits pi's session GUID (pi gives bash no session-id env of its own; the GUID
is stable across resume — it's read from the persisted session header). pi can't
block a stop, so on `agent_end` it runs `teamup-hook stop` with `{cwd, session_id}`
and, on exit 2, injects the unread summary via
`pi.sendUserMessage(..., {deliverAs:"followUp"})` so the agent handles it before
going idle; `session_shutdown` runs `teamup-hook session-end`. A dedupe guard
avoids re-injecting an unchanged nudge (no autonomous loop). **Any other harness**
reuses `teamup-hook` the same way: expose the session GUID as `$TEAMUP_SESSION`
for `join`, and pass `.session_id` (+ `.cwd`) to the hook on stdin.

### Known limitations & caveats

- **No inbound wake.** Hooks fire only at *turn-end*; nothing wakes a *fully idle*
  agent when a peer speaks (a file channel has no push). The only idle listener is
  a backgrounded `wait --timeout 0` (§4), **re-armed after each fire**. Hooks stop
  an agent forgetting *between its own turns*; staying live while idle still needs
  an armed `wait` or a harness inbound-message API.
- **pi's nudge is ignorable by design.** claude-code's Stop hook exits 2 and
  *hard-blocks* the turn end; pi can't block, so it *injects* a follow-up the agent
  could still ignore (and the dedupe guard won't re-push an unchanged nudge). So a
  pi agent stays a slightly weaker channel citizen than claude-code — expected.
- **Handle guard needs a GUID and isn't atomic.** It refuses a handle held by a
  different session only when both sides have a session GUID — a GUID-less harness
  is unprotected and can stomp a held handle. Two sessions first-claiming the *same
  brand-new* handle in the same instant can both pass the check (TOCTOU, same
  last-writer-wins class as the registry). A crashed session leaves its
  `members/{handle}` behind, so a *different* session can't reclaim that handle
  until a same-GUID resume or a manual `rm` of the member file.

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
| `ask {subject} --as H [--to P] -- <question>` | post a question; `--to` aims it at peer `P` (shows as their `asks_for_me`) |
| `ack {subject} --as H [--re <seq>] -- [note]` | answer/clear an ask (default `--re` = latest peer msg); any message from you also clears it |
| `recv {subject} --as H` | summary line + peers' messages since last read (non-blocking) |
| `status {subject} --as H` | summary line only; cursor untouched; exit `0`=clean `1`=unread `2`=ask-for-you |
| `status --as H` | no subject: list every team this handle is on + member count |
| `wait {subject} --as H [--timeout S]` | block until a peer speaks or timeout (`--timeout 0` = forever; use for background idle waits) |
| `roster {subject}` | who's on the channel |
| `peek {subject} [--last N]` | recent history (default 20) |
| `leave {subject} --as H` / `leave --all --as H` | disconnect |
| `channels` | list active subjects |

Every message has a stable `#seq` id (its line number); `recv`/`peek`/`wait`
print it so you can `ack --re <seq>` a specific message.

State lives under `$SUSS_TEAMUP_DIR` (default `/tmp/suss-teamup`). Cleared on
reboot; that's fine — channels are ephemeral per work session.
