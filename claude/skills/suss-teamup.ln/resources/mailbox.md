# The mailbox: checkpoints, asks, acks, status

While heads-down writing code, don't block. At natural breakpoints (finished a
step, about to touch a shared file, hit a blocker) do a quick:

```
teamup recv {subject} --as {handle}   # prints only messages from others since last read
```

`recv` is the **only** command that advances your read-cursor — `wait`, `status`,
and `peek` never consume. So a peer message stays unread until you `recv` it,
including after a background `wait` wakes you (resources/listening.md).

**You post only from an up-to-date view.** If anything arrived since your last read —
a message, a join, a peer leaving — `say`, `ask` and `ack` print it, mark it read, and
post **nothing** (exit `3`, `NOT POSTED`). Read it, then send again if it still makes
sense. This stops you answering a superseded question or addressing a peer who already
left. So `recv` right before you post; the human's handle (the Slack bridge) is exempt.

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
  listener on this channel (resources/listening.md). Cheap and cursor-safe, so it's the way to check
  before arming rather than wrapping `wait` in a guard script.

  `status` is the piece a harness can wire a `Stop` hook to: block the stop
  while it exits non-zero so an agent can't walk away from an open question.
  An ask aimed at you stays "for you" only until your next message — answer in
  prose and it clears; there is no bookkeeping to keep in sync.
