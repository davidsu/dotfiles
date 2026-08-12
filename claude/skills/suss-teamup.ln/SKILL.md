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
> handle is derived from your session name (§Your handle).
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

- `/suss-teamup help` (aliases `-h`, `--help`) → **print the command surface** and
  stop — don't join anything. List every `/suss-teamup …` form from this section
  (join, disconnect/teardown, erase, status, spawn, handoff) and then run
  `teamup help` to show the raw script subcommands. Treat the literal word `help`
  as this command, not a channel named "help".
- `/suss-teamup {subject}` → **join** channel `{subject}`.
- `/suss-teamup {subject} disconnect` → **leave** `{subject}`.
- `/suss-teamup disconnect all` → **leave every** channel you're on.
- `/suss-teamup teardown` → **alias for `disconnect all`** — leave every channel
  you're on (runs `teamup leave --all --as {handle}`).
- `/suss-teamup erase {subject}` (alias `cleanup`) → **delete the channel** — runs
  `teamup erase {subject}`, removing the channel dir and its session-registry rows.
  Refuses if members remain (leave first) unless you pass `--force`.
- `/suss-teamup status` → **overview**: run `teamup status --as {handle}` (no
  subject) to list every team you're on + its member count. Treat the literal
  word `status` as this command, not a channel named "status".
- `/suss-teamup spawn [pi|claude|codex] [flavor] [new|subject]` → **spawn a peer agent**
  in a new tab, joined to a shared channel. Agent defaults to `claude`, channel to
  `new`. An optional **flavor** gives the peer a role + protocol — codified so far:
  `handoff`; planned: `sidecar`, `tester`, `reviewer` (see §Spawn a cooperating
  agent). Tokens are recognised by value, so order is loose (`spawn handoff`,
  `spawn codex tester pair-x`).
- `/suss-teamup handoff …` → alias for `/suss-teamup spawn handoff …` — **the `handoff`
  spawn flavor**: brief the peer against a durable task file, verify it's *smart*
  before it grills the user, and gate all code behind that grill (read
  [resources/handoff.md](resources/handoff.md) before running one).

If no subject is given on a join, ask the user for one — don't guess.

## Your handle — it's your session name

**Don't invent a handle.** Omit `--as` on join and the script derives it from your
**claude session name** (the `/rename` banner above your prompt, or `--name` at
launch) — so the identity peers address is the one the user can actually see on
their screen. `teamup session-name` prints what it would pick.

```
teamup join {subject} --pwd "$PWD" --doing "..."      # handle = your session name
```

Only pass `--as {handle}` when you were *given* one (a spawner assigns its peer's
handle, §Spawn) or when the script says it can't derive one — an unnamed session
(claude auto-derives a name and tags it `nameSource: derived`; that's noise, not
identity), or a harness with no session-name file (pi, codex). Then pick something
short and stable: your worktree/branch basename or your role (`auth-wt`,
`reviewer`). Either way, **remember it** — you pass `--as {handle}` on every
*subsequent* call this session. It keys your read-cursor and your roster entry.

### If the user renames your session mid-flight

Your handle is now a name shown nowhere, and the user can't tell which session the
channel is talking about. Re-key with a single command:

```
teamup rename --as {old-handle} --to {new-session-name}
```

It moves your presence, read-cursor and listener across **every** channel you're on
(a session name isn't per-channel) and posts one line so peers re-map. Unread stays
unread — the cursor travels with you. On claude-code the Stop hook nudges you once
when it spots the drift (§6), so you don't have to notice it yourself. If it refuses
because a live peer already holds that name, say so on the channel and keep your
current handle.

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

## 1a. Orient on the written context — related suss-tasks

The live channel isn't the only coordination surface. Joint work usually has a
**task file under `suss-tasks/`** (see the `suss-tasks` skill) capturing the goal,
decisions, and status. On join, **check for a suss-task about this work and read
it** — it's the context for *what* the team is doing and *why*, and unlike the
channel it persists across sessions. Use it as a second, durable channel: record
decisions, findings, and hand-offs there. The message channel is ephemeral (and
`erase`-able); the task file is the lasting record peers and future sessions rely on.

## 2. Huddle — align before you build (blocking)

Once ≥1 peer is present, describe concretely: **what** you're implementing,
**which pwd/worktree** you're in, and the **shape** of your intended solution
(file, function signature, data shape). Then block for replies:

```
teamup say  {subject} --as {handle} -- "<your message; put free text after -->"
teamup wait {subject} --as {handle} --timeout 110   # blocks until a peer speaks
```

Keep `--timeout` ≤ 110s so it fits the default Bash budget; for a longer hold,
raise the Bash tool timeout to match. Run this one in the **foreground** — a
bounded wait that expires exits with nothing to read, which backgrounded would land
on you as a phantom message (§4). Loop say→wait until you've reached an
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

`recv` is the **only** command that advances your read-cursor — `wait`, `status`,
and `peek` never consume. So a peer message stays unread until you `recv` it,
including after a background `wait` wakes you (§4).

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

  Its summary also reports `listener=live|none` — whether you have an armed idle
  listener on this channel (§4). Cheap and cursor-safe, so it's the way to check
  before arming rather than wrapping `wait` in a guard script.

  `status` is the piece a harness can wire a `Stop` hook to: block the stop
  while it exits non-zero so an agent can't walk away from an open question.
  An ask aimed at you stays "for you" only until your next message — answer in
  prose and it clears; there is no bookkeeping to keep in sync.

## 3b. Reviewing a teammate's work

When you're the reviewer/boss signing off on another agent's implementation:

**CRITICAL**: Read [reviewer.md](resources/reviewer.md) before you approve any teammate's
work. The core rule: review against the **locked decision/plan**, not just code quality —
read the actual diff for every load-bearing claim (never trust the implementer's summary),
and send deviations back to the decision-owner instead of blessing the shortcut.

## 4. Background wait — get woken while idle

> 🚨 **On pi, skip this whole section — you have no listener to arm.** pi's extension
> watches the channel with `fs.watch` and starts a turn the moment a peer speaks, even
> on a fully idle agent. So on pi:
> - **Never** run `wait --timeout 0` — the extension **blocks** the call. There is
>   nothing to arm and nothing to re-arm.
> - **Never loop `wait` to stay reachable.** `say` → `wait` → "still quiet, re-arming"
>   → `wait` is the thrashing loop: it burns a turn per lap and reaches nobody. When
>   there is nothing to do, **end your turn** — that is how you go idle *and* stay
>   reachable here.
> - A **bounded foreground `wait`** is still right during a live huddle (§2), where you
>   read the result yourself in-turn. Once it expires with nothing, the huddle is over:
>   end the turn instead of waiting again. (`teamup` says so itself on the second expiry
>   with nothing new on the channel — on **any** harness.)
>
> The rest of this section is the **claude-code** protocol, where an armed background
> `wait` is the only wake signal and the Stop hook enforces one.

When you'd otherwise be waiting (peer is still working, nothing to do), launch a
blocking wait as a **background** Bash command with **`--timeout 0`** (waits
indefinitely):

```
teamup wait {subject} --as {handle} --timeout 0
```

Run it with `run_in_background: true`. With `--timeout 0` the watcher stays
armed across your whole work-turn instead of expiring after ~110s, so it's still
listening when a peer finally speaks. When one does, it exits and the harness
re-invokes you — a poor-agent's interrupt.

**`wait` is signal-only: it does NOT consume the message.** It just unblocks
when a peer speaks; the message stays unread. On wake you **must `recv`** to
actually read it — `recv` is the only reader that advances your cursor. (This is
deliberate: a background `wait`'s stdout lands in a detached task-output file you
never read, so if `wait` advanced the cursor the message would be silently lost.)
So the on-wake order is **`recv` → then re-arm `wait`**. **Re-arm after each fire**
if you're still idle. Arming is idempotent and safe to repeat: if a live wait is
already armed for this handle, the second one **stands by** — it blocks instead of
exiting, and takes over only if the first dies. (It must not exit: an exiting
background command IS the wake signal, so a no-op exit would land on you as a
message that isn't there.)

**Two rules that keep a wake honest** — both learned from agents chasing phantom
messages for hours:

- **The backgrounded command must BE the wait — not something that starts one.**
  A prefix in the *same* process is fine (`cd /some/wt && teamup wait … --timeout 0`);
  what breaks is anything that spawns the wait and returns, `nohup teamup wait … &`
  above all, and anything chained *after* it. If you do put a command before it,
  separate with `;` rather than `&&` — a non-zero exit upstream of `&&` short-circuits
  the wait away, and you get an unexplained background exit *and* no listener. Those exit immediately, and their exit
  is the wake — you get woken by your own wrapper. You don't need a liveness guard
  around it either: arming is idempotent (see above), and `teamup status` reports
  `listener=live|none` if you want to look before arming.
- **`recv` before you believe a wake.** A wake means "a background command exited",
  nothing more. `wait` now exits only with something unread, and tells you which
  case it was on its last line (`wake: peer-spoke …` / `wake: none reason=…`), but
  one honest false alarm survives by construction: a message that lands mid-turn
  fires your listener immediately, and the harness only reports that exit after your
  turn ends — so if you already read it at a checkpoint (§3), the wake arrives with
  nothing left to read. `recv` says `unread=0`; that's the whole story. Just re-arm
  and carry on — don't announce a message, and don't go hunting for a lost one.
- **A `wake: peer-joined` wake is the exception to that** — it is deliberate, and
  `unread=0` is correct rather than a bug. A new peer is on the channel: if you were
  idle waiting for company (§1), this is your cue to open the huddle (§2). If you
  weren't, re-arm and carry on. A peer *leaving* never wakes you — if their parting
  message mattered, that `say` woke you on its own.

**Never background a *bounded* wait.** A `--timeout` that expires exits with nothing
to read, which is exactly the false wake this section is about. Bounded waits are for
blocking in the **foreground**, where you read the result yourself in-turn (that's the
§2 huddle loop). Backgrounded, always `--timeout 0`.

**And never loop bounded waits to stay reachable.** Two expiries in a row with nothing
new on the channel means the huddle is over and you are just burning a turn per lap;
`wait` tells you so (`STOP LOOPING: …`) and names the way to go idle on your harness.
Arm one background `--timeout 0` here and end your turn.

Also worth knowing: the harness wakes you when **any** background command exits, not
just a `wait`. A backgrounded build, poll loop, or unrelated script finishing looks
identical from inside the session. `recv` is what tells the two apart.

On **claude-code this re-arm is enforced**, not left to memory: the Stop hook
(`--require-listener`, §6) refuses to let you go idle on a channel without a live
`wait`, so a peer message can always reach you. (pi must NOT do this — its extension's
`fs.watch` watcher wakes it and blocks an armed `wait` outright; see the box above and §6.)

> ⚠️ Still best-effort, not a true interrupt: a background command re-invokes you
> only **between** turns — while heads-down in a turn you're unreachable. So a
> long-armed `wait` is not a substitute for a deliberate `recv` at every checkpoint
> (§3). The accepted cost of enforce-and-re-arm: every peer message = one wake + one
> re-arm turn. (A churn-free external waker via tmux `send-keys` was considered and
> **ruled out** — see §6.)

## Spawn a cooperating agent

`/suss-teamup spawn [pi|claude|codex] [flavor] [new|subject]` launches another agent in a
new Ghostty tab, already joined to a shared channel — for **cross-model pairing**
(claude ⇄ pi ⇄ codex) or, with a **flavor**, a role the peer plays. Agent defaults to
`claude`; channel defaults to a new one.

**Flavors** attach a role + protocol to the spawn. Codified so far: **`handoff`** — hand
a task to a fresh agent and hold its hand to *smart* before it touches code. **Doing a
handoff? Read [handoff.md](resources/handoff.md) first** (durable task file → brief →
verified understanding-check gates the grill → no code before the grill → coordinate the
push) — don't wing it from memory. Planned: `sidecar`, `tester`, `reviewer`. A bare
`spawn` (no flavor) is just a joined peer you then huddle with (§2).

1. **Resolve agent + channel.** Agent: `pi`, `claude`, or `codex` (default `claude`).
   Channel: a given `subject` → use it; `new` (or omitted) → pick a short slug
   (e.g. `pair-auth`, `handoff-x`) — avoid names starting with `spawn`.
2. **Join it yourself first**, so you're present when the peer arrives:
   `teamup join {subject} --pwd "$PWD" --doing "spawning a {agent} peer"`.
3. **Spawn the peer:** `scripts/teamup-spawn {claude|pi|codex} {subject} [--as {handle}]`
   — opens a tab in your `$PWD` running the agent, which joins `{subject}`. claude/pi
   invoke the skill by slash command; codex gets a plain-language prompt naming the skill
   (codex argv is a prompt, not a command dispatcher). **You assign the peer's handle**
   (`--as`, default `{subject}-peer{n}`, checked free against the roster) and it's final:
   a claude peer launches with `--name {handle}`, so its session name *is* its channel
   handle and it derives that handle on join — one name in its banner, its tab, and the
   roster. Give it a descriptive one (`apper-test-runner`) — that string is how the user
   will find its session. Once
   the peer is interactive, it also inherits the spawning session's **color** (random if
   you have none) by keystroking `/color` into its tab — this briefly steals focus to the
   peer's tab. Pass **`--no-steal`** (alias `--no-color`) to skip the color step.
4. **Huddle** (§2). For a handoff, post the context the peer needs on the channel
   before it gets going; for pairing, align on who owns what.

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
  the stop** while any channel (a) has unread messages [`recv` clears] or, with
  **`--require-listener`** (claude-code only), (b) has no live background `wait`
  listener [arm one to clear; liveness = the wait's `.wait.{handle}` pidfile +
  `kill -0`]. Both clear on the agent's next action, so it can't loop; fails open
  (exit 0) on any missing input or tool error. **(b) is opt-in** because it assumes
  the agent can launch a persistent background `wait` — pi must NOT pass the flag
  (it stays reachable via `fs.watch`, not a `wait` process).
- `teamup-hook stop` also blocks **once** when your session name and your channel
  handle disagree (the user `/rename`d you mid-flight), telling you the exact
  `teamup rename` to run. Once-only, keyed on the new name: `rename` can legitimately
  refuse (a live peer holds that name), and a block you can't clear would wedge the
  session. A *further* rename nudges again. **Exception:** if the session name is
  itself a channel name it's a pre-fix spawn (spawn used to pass `--name {subject}`),
  not a user rename — re-keying there would hand you a channel-shaped handle and
  orphan every message that named the old one, so the nudge instead asks you to get
  the *user* to `/rename` the session to your handle.
- `teamup-hook session-end` auto-`leave`s this session's channels so rosters stay honest.
- `join` also **refuses a handle already held by a different session** (cursor
  files are keyed by handle, so two live sessions sharing one would race it).

**claude-code wiring** (`~/.claude/settings.json`):

```json
"hooks": {
  "Stop":       [{ "hooks": [{ "type": "command", "command": "~/.claude/skills/suss-teamup/scripts/teamup-hook stop --require-listener", "timeout": 10 }] }],
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
avoids re-injecting an unchanged nudge (no autonomous loop). For **idle wake** pi
also runs a persistent `fs.watch` on the channel dir (armed at `session_start`,
torn down at `session_shutdown`): on a change with unread it `sendUserMessage`s to
wake even a fully idle pi agent — so pi needs no armed `wait` and calls `teamup-hook
stop` **without `--require-listener`**. Because the watcher owns the wake, the
extension also **blocks** any bash `tool_call` that arms an idle listener
(`teamup wait … --timeout 0`) with the §4 pi rule: agents kept re-arming a listener
that does nothing here, then looping around it. **Any other harness** reuses `teamup-hook`
the same way: expose the session GUID as `$TEAMUP_SESSION` for `join`, pass
`.session_id` (+ `.cwd`) to the hook on stdin, and pass `--require-listener` only if
its agent can hold a persistent background `wait`.

**codex (Codex CLI):** codex needs **no wrapper extension** — it natively does what
the other harnesses bolt on. `join` reads the GUID from `$CODEX_THREAD_ID`, which
codex exports into the agent's shell; codex's `Stop` hook event carries the **same**
value as `.session_id`, so GUID routing matches end-to-end (verified). Codex honors a
`Stop` hook that exits 2 — it blocks the turn-end and re-invokes the agent with the
hook's stderr, exactly like claude-code. Wiring is `codex/hooks.ln.json` →
`~/.codex/hooks.json` (the hooks feature, `[features].hooks`, is **on by default** —
no flag needed); it runs `teamup-hook stop` **without `--require-listener`**. Codex
limitations: (1) **no idle-wake** — its exec harness doesn't keep a backgrounded
`wait` alive and doesn't auto-start a turn when a bg process exits, so a peer message
can't wake a *fully idle* codex (the Stop hook only catches unread that piled up
*during* a live turn). (2) **no `SessionEnd` event** — no auto-`leave`, so a codex
roster entry goes stale on exit (channels are ephemeral, so it self-heals on reboot).
(3) **the hook is global** — `~/.codex/hooks.json` fires `teamup-hook` on *every*
codex session; that's fine because `teamup-hook` fail-opens (exits 0) for any session
not on a channel. (4) codex loads hooks **at session start**, so a codex already
running when the hook was installed won't have it until restarted.

### Joined-teams statusline

`teamup teams --session {guid}` prints this session's joined channels as one compact
line (markers: `!` = an ask aimed at you, `*` = unread), or nothing when on no teams.
The claude statusline (`claude/statusline.ln.sh`) and the pi footer
(`pi/agent/extensions/claude-code-footer.ln.ts`) both call it and render an `⇄ …`
segment. Codex has **no** custom-command statusline (its `/statusline` only toggles
built-in items), so it shows no teams segment — the Stop-hook unread surfacing is its
equivalent signal.

### Known limitations & caveats

- **Idle wake is solved per-harness — but only for a LIVE session.**
  - *claude-code:* the Stop hook (`--require-listener`, §6) won't let the agent go
    idle on a channel without a live background `wait`, so a peer message always
    reaches it. Cost: every message = one wake + one re-arm turn (accepted).
  - *pi:* the extension's `fs.watch` watcher wakes a fully idle agent with no re-arm
    (the watcher owns the wake).
  - **Boundary — does NOT cover session DEATH:** both keep an *alive* idle session
    reachable; neither resurrects a *crashed/exited* session. A completion guarantee
    across session death needs a gastown-style external supervisor (durable work
    ledger + daemon + respawn) — deliberately out of scope for a no-daemon file
    channel. A churn-free wake via tmux `send-keys` was considered and **ruled out**
    (no tmux). See `suss-tasks/learn_gastown_idle.md`.
- **The anti-thrash guards are heuristics, and one of them is stateful.** The
  bounded-wait `STOP LOOPING` line fires on the *second* expiry with the channel
  **unchanged** in between, so a lap in which anyone (you included) speaks resets it —
  a slow thrash interleaved with chatter never trips it, by design. Its state is one
  file per handle (`.expiry.{handle}`), moved by `rename` and dropped on `leave`. pi's
  block on `wait --timeout 0` matches the *command string*, so a command assembled at
  runtime (via a variable or a wrapper script) slips through — harm bounded to one
  useless process, since the watcher wakes the agent either way.
- **pi's nudge is ignorable by design.** claude-code's Stop hook exits 2 and
  *hard-blocks* the turn end; pi can't block, so it *injects* a follow-up the agent
  could still ignore (and the dedupe guard won't re-push an unchanged nudge). So a
  pi agent stays a slightly weaker channel citizen than claude-code — expected.
- **handle == session name is a claude-only guarantee.** Only claude-code writes a
  live session-name file (`~/.claude/sessions/{pid}.json`) and only claude has a
  launch-name flag, so only claude peers derive their handle and only claude sessions
  get the drift nudge. pi and codex peers spawn unnamed and pick their own handle —
  their channel identity can still be a name the user sees nowhere.
- **Handle guard needs a GUID and isn't atomic.** It refuses a handle held by a
  different session only when both sides have a session GUID — a GUID-less harness
  is unprotected and can stomp a held handle. Two sessions first-claiming the *same
  brand-new* handle in the same instant can both pass the check (TOCTOU, same
  last-writer-wins class as the registry). A crashed session leaves its
  `members/{handle}` behind, so a *different* session can't reclaim that handle
  until a same-GUID resume or a manual `rm` of the member file.
- **Presence self-heals on activity.** `say`/`ask`/`recv`/`wait` re-create your
  `members/{handle}` entry and registry row if they went missing (a resume, a
  stale `session-end`, a manual `rm`) — so an agent that keeps talking can't
  silently drop off the roster/statusline while peers wrongly read it as gone.
  A no-op when you're already a member (your `doing`/`joined` are preserved) and
  it fires no `ping`; it only restores a *missing* entry, never clobbers one a
  live peer holds. `leave` is still the way to actually go — but a lone `say`
  afterward puts you back. It **restores only, never invents**: a handle that has
  never appeared on the channel is refused with "run join" — otherwise one typo in
  `--as` materialises a phantom member that peers see arrive, get woken by, and
  wait on forever.
- **A wake is a hint, not a fact — always `recv` before believing it.** The harness's
  only wake signal is "a background command exited", so nothing richer than that can
  be delivered. `wait` therefore exits only on something this handle has not already
  seen (a duplicate arm stands by rather than exiting, and `.woken.{handle}` stops a
  re-armed wait re-firing on the message that just woke you), but two false alarms
  survive by construction: (a) a message landing mid-turn fires your listener at once
  while the harness reports that exit only after the turn ends — so if you read it at
  a checkpoint in between, the wake arrives empty; (b) *any* background command
  exiting wakes you, teamup or not. `recv` → `unread=0` → re-arm and move on. See §4.
- **A join ping wakes you but is not mail.** A peer's `join` wakes an armed listener
  (labelled `wake: peer-joined`) — deliberately, as a safety net for a peer who joins
  and then waits to be briefed instead of speaking first, which §1/§2 discourage but
  cannot prevent. A `bye` never wakes anyone: a departure isn't actionable, and a
  leaving peer's parting `say` wakes you by itself. Neither is counted as unread,
  marks the statusline, or blocks your idle; only `say`/`ask`/`ack` do. So `recv` can
  print more lines than its own `unread=` count — the extras are presence, as context.
- **Two listeners can still double-wake you, rarely.** A foreground huddle `wait` and
  an armed idle listener can wake on the same channel event; the idle one defers a
  second and re-checks so the foreground reader normally wins, but a slower reader
  can lose that race and you get a second, empty wake. Same treatment as any wake:
  `recv`, see `unread=0`, carry on.
- **Ownership handoff has a ~2s gap.** When an idle listener fires, its pidfile is
  freed and a standby claims it within one poll. In that window the Stop hook sees no
  live listener and tells you to arm one; the arm then just stands by, so the cost is
  one extra harmless process, never a loop. The claim verifies afterwards which pid actually
  landed in the file, which narrows the window for two standbys racing a dead owner
  but does not close it — one can write-and-verify before the other writes, and both
  then believe they own. Cost is one duplicate wake, and it self-heals.
- **Upgrading the script does not fix running listeners.** A `wait` already blocking
  keeps executing the code it started with, so after a change to `teamup` its live
  listeners keep the old behaviour until they exit — and they hold the pidfile, so a
  correct new arm stands by behind them. Restart them (`leave` + re-`join`, or end the
  session) if you need the new behaviour on a channel that already has one armed.

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
| `join {subject} [--as H] [--pwd P] [--doing T]` | announce + register + show roster/history. `--as` defaults to your session name |
| `session-name [--session G]` | the handle your session name implies (exit 1 if it has no user-chosen name) |
| `rename --as H --to N` | re-key H → N on every channel you're on (presence, cursor, listener, registry) + tell peers |
| `say {subject} --as H -- <text>` | post a message (alias: `send`) |
| `ask {subject} --as H [--to P] -- <question>` | post a question; `--to` aims it at peer `P` (shows as their `asks_for_me`) |
| `ack {subject} --as H [--re <seq>] -- [note]` | answer/clear an ask (default `--re` = latest peer msg); any message from you also clears it |
| `recv {subject} --as H` | summary line + peers' messages since last read (non-blocking); join/leave pings print as context but aren't counted as unread. **The only reader that advances the cursor.** |
| `status {subject} --as H` | summary line only (incl. `listener=live\|none`); cursor untouched; exit `0`=clean `1`=unread `2`=ask-for-you |
| `status --as H` | no subject: list every team this handle is on + member count |
| `teams --session G [--pwd P]` | compact one-line joined channels for a statusline (`!` ask, `*` unread); empty when on none |
| `wait {subject} --as H [--timeout S]` | block until a peer speaks something you have not read, or timeout (`--timeout 0` = forever, for background idle waits; a second one stands by instead of exiting). Exits `0` only with something to read, `1` on timeout/left-channel, and names the case on its last `wake:` line. A second expiry with nothing new on the channel says `STOP LOOPING` + how to go idle on your harness. **Signal-only: does NOT consume — `recv` after waking.** Not on pi for idle waiting (§4). |
| `roster {subject}` | who's on the channel |
| `peek {subject} [--last N]` | recent history (default 20) |
| `leave {subject} --as H` / `leave --all --as H` | disconnect |
| `erase {subject} [--force]` (alias `cleanup`) | delete the channel + its registry rows; refuses if members remain unless `--force` |
| `channels` | list active subjects |

Every message has a stable `#seq` id (its line number); `recv`/`peek`/`wait`
print it so you can `ack --re <seq>` a specific message.

State lives under `$SUSS_TEAMUP_DIR` (default `/tmp/suss-teamup`). Cleared on
reboot; that's fine — channels are ephemeral per work session.
