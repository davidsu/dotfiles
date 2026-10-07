# Listening: background waits, wake rules, false wakes

> 🚨 **On pi, skip this whole section — you have no listener to arm.** pi's extension
> watches the channel with `fs.watch` and starts a turn the moment a peer speaks, even
> on a fully idle agent. (That watcher wakes on **any** unread — the "meant for you"
> rule below applies to `wait`, so it doesn't thin out pi's wake-ups yet.) So on pi:
> - **Never** run `wait --timeout 0` — the extension **blocks** the call. There is
>   nothing to arm and nothing to re-arm.
> - **Never loop `wait` to stay reachable.** `say` → `wait` → "still quiet, re-arming"
>   → `wait` is the thrashing loop: it burns a turn per lap and reaches nobody. When
>   there is nothing to do, **end your turn** — that is how you go idle *and* stay
>   reachable here.
> - A **bounded foreground `wait`** is still right during a live huddle (SKILL.md → Huddle), where you
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
listening when a message meant for you arrives (resources/listening.md). When one does, it exits and the harness
re-invokes you — a poor-agent's interrupt.

**A wait wakes you only for messages meant for you.** On a busy channel every agent
used to wake for every message, which buried the user's own conversation under
wake-up turns. Every message still lands on the shared channel for everyone to `recv`;
what changed is only who gets **woken**. A `wait` (idle or bounded) decides, in order:

1. a join `ping` → wakes you (a new peer is the cue to huddle; a `bye` never wakes)
2. `@{you}` or `@all` anywhere in the message → wakes you (`ask --to {you}` writes the `@`)
3. an `@` of anyone else, the human included → **doesn't** wake you, whoever wrote it
4. a reply — `ack --re N`, or a `say` opening `ack #N` / `re #N` → wakes only N's author
5. anything else is unaddressed → wakes you if it's from the human (`$TEAMUP_SLACK_HANDLE`,
   default `david`, i.e. their Slack replies) or if you are the **one** other agent here

The one exception is the human's own handle (`$TEAMUP_SLACK_HANDLE`), which is the Slack
bridge: it mirrors the whole channel, so its wait fires on every line. Under the rules above
it slept through agent-to-agent traffic and posted it to Slack only when someone next @'d the
human (23 minutes of lag observed 2026-10-06).

So on a channel with 3+ agents, an unaddressed update wakes nobody. It still counts as
**unread**: you see it at your next `recv`, and the Stop hook still makes you read it
before going idle. **Address what needs an answer** — `ask --to {peer}` or `@{peer}` —
and use `@all` for something every agent must act on now.

**`wait` is signal-only: it does NOT consume the message.** It just unblocks
when a message meant for you arrives; it stays unread. On wake you **must `recv`** to
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
  turn ends — so if you already read it at a checkpoint (resources/mailbox.md), the wake arrives with
  nothing left to read. `recv` says `unread=0`; that's the whole story. Just re-arm
  and carry on — don't announce a message, and don't go hunting for a lost one.
- **A `wake: peer-joined` wake is the exception to that** — it is deliberate, and
  `unread=0` is correct rather than a bug. A new peer is on the channel: if you were
  idle waiting for company (SKILL.md → Join), this is your cue to open the huddle (SKILL.md → Huddle). If you
  weren't, re-arm and carry on. A peer *leaving* never wakes you — if their parting
  message mattered, that `say` woke you on its own.

**Never background a *bounded* wait.** A `--timeout` that expires exits with nothing
to read, which is exactly the false wake this section is about. Bounded waits are for
blocking in the **foreground**, where you read the result yourself in-turn (that's the
SKILL.md → Huddle huddle loop). Backgrounded, always `--timeout 0`.

**And never loop bounded waits to stay reachable.** Two expiries in a row with nothing
new on the channel means the huddle is over and you are just burning a turn per lap;
`wait` tells you so (`STOP LOOPING: …`) and names the way to go idle on your harness.
Arm one background `--timeout 0` here and end your turn.

Also worth knowing: the harness wakes you when **any** background command exits, not
just a `wait`. A backgrounded build, poll loop, or unrelated script finishing looks
identical from inside the session. `recv` is what tells the two apart.

On **claude-code this re-arm is enforced**, not left to memory: the Stop hook
(`--require-listener`, resources/hooks.md) refuses to let you go idle on a channel without a live
`wait`, so a peer message can always reach you. (pi must NOT do this — its extension's
`fs.watch` watcher wakes it and blocks an armed `wait` outright; see the box above and resources/hooks.md.)

> ⚠️ Still best-effort, not a true interrupt: a background command re-invokes you
> only **between** turns — while heads-down in a turn you're unreachable. So a
> long-armed `wait` is not a substitute for a deliberate `recv` at every checkpoint
> (resources/mailbox.md). The accepted cost of enforce-and-re-arm: every message meant for you = one wake +
> one re-arm turn. (A churn-free external waker via tmux `send-keys` was considered and
> **ruled out** — see resources/hooks.md.)
