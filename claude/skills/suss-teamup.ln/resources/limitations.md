# Known limitations and caveats

- **Idle wake is solved per-harness — but only for a LIVE session.**
  - *claude-code:* the Stop hook (`--require-listener`, resources/hooks.md) won't let the agent go
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
- **handle == session name holds on claude, pi and codex.** claude-code writes
  a live session-name file (`~/.claude/sessions/{pid}.json`); pi has no such file, so its
  extension exports `TEAMUP_SESSION_NAME` from `pi.getSessionName()` instead (resources/hooks.md) —
  different plumbing, same guarantee, and the drift nudge works for both since it goes
  through `teamup session-name`. codex keeps its thread name in its state DB, which
  `teamup` reads directly; the catch is that an AI title counts as a name there. Two pi
  caveats: the export is refreshed per turn, so a `/banner` mid-turn reaches the channel
  only on the next one; and the drift nudge only reaches pi when the hook is spawned by
  the extension (it inherits the env), never from a bare shell.
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
  exiting wakes you, teamup or not. `recv` → `unread=0` → re-arm and move on. See resources/listening.md.
- **A join ping wakes you but is not mail.** A peer's `join` wakes an armed listener
  (labelled `wake: peer-joined`) — deliberately, as a safety net for a peer who joins
  and then waits to be briefed instead of speaking first, which SKILL.md → Join/SKILL.md → Huddle discourage but
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
