closed
# teamup: background `wait` silently eats messages (advances cursor into a detached output file)

## Summary

`teamup wait` advances the reader's cursor exactly like `recv` when a peer message arrives, but in the
documented background-idle pattern (`wait --timeout 0` run detached + re-armed by the Stop hook) its
stdout lands in a task-output file the agent never reads. The cursor moves past the message, so the
agent's next `recv` returns "nothing new" — the message is silently consumed. Two peers each waiting
on the other then deadlock: each posted/answered, but neither `recv` ever surfaces the other's reply.

## Details

### Mechanism

In `scripts/teamup`, the `wait)` block (around line 303-313) does, on fresh lines:

```sh
printf '%s' "$(linecount "$file")" > "$(cursor "$SUBJECT" "$HANDLE")"   # advances cursor
printf '%s\n' "$fresh" | pretty                                         # prints to stdout
exit 0
```

`wait` and `recv` share one cursor file (`.cursor.$HANDLE`). `wait` is therefore **destructive** —
firing it consumes the messages. That's fine for a foreground `wait` (the human/agent sees the
stdout). It is **broken for the skill's own recommended idle pattern**: the SKILL tells agents to run
`wait --timeout 0` in the **background** and re-arm it after each fire (and the `teamup-hook stop
--require-listener` enforces a live background `wait`). When that background `wait` fires:

1. its stdout (the actual peer message) is written to the detached background task's output file,
2. the shared cursor is advanced to the channel tail,
3. the agent is notified only that "the background command completed" — it does not read the output
   file, it calls `recv`,
4. `recv` sees the cursor already at the tail → "nothing new".

The message is lost from the agent's point of view. If both peers use the background-wait pattern,
each thinks it is still waiting for the other → deadlock. Observed live 2026-06-25 between two agents
on a shared channel.

### Repro

1. Agent A: `teamup wait <chan> --as A --timeout 0` in the background (as the skill instructs).
2. Agent B: `teamup say <chan> --as B -- "hello"`.
3. A's background `wait` fires, prints "hello" into A's background task output file, advances A's cursor.
4. A (woken by task completion) runs `teamup recv <chan> --as A` → "nothing new". "hello" is gone.

### Why it matters

This is the skill's primary idle-reachability mechanism (§4 background wait, §6 `--require-listener`
Stop hook). As written, it is a data-loss path for exactly the messages it exists to deliver.

## Proposed fix

**Make `wait` cursor-neutral — only `recv` advances the cursor.** `wait` should block until a peer
speaks, then exit **without** advancing the cursor (signal-only, like `status`/`peek`). The woken
agent then runs `recv` to actually read + advance. The message stays "unread" across the wake, so the
foreground `recv` surfaces it.

Required companions for that fix:
- **Avoid the re-arm busy-loop:** a cursor-neutral `wait` re-armed immediately would re-fire instantly
  on the still-unread message. Either (a) have `wait` block on changes past a *local* high-water mark
  captured at its own start (not the shared cursor), so a re-armed `wait` only fires on genuinely new
  lines; or (b) codify on-wake ordering as **recv → then re-arm wait** (recv clears unread, so the
  re-armed wait blocks). (a) is more robust since it doesn't depend on agent discipline.
- Update the skill doc (§3/§4/§6) to state plainly: **`wait` never consumes; `recv` is the only
  reader that advances the cursor.**

Alternative (heavier): `wait` drains fresh lines into a per-handle inbox sidecar that `recv` also
reads, so content survives even if the background stdout is dropped. More moving parts than making
`wait` non-destructive; not preferred.

## Notes

- 2026-06-25: Found while two agents coordinated on the `previewLens` channel. Recovered the "lost"
  peer message by `cat`-ing the background task `.output` files directly — confirming the content was
  delivered to the file and the cursor had advanced past it.
- Related: [group_spawned_tabs.md](/suss-tasks/group_spawned_tabs.md) (other open teamup work);
  [done/verify_teamup_fix.md](/suss-tasks/done/verify_teamup_fix.md).

## Resolution (2026-06-25)

Took proposed fix (a). `scripts/teamup`:
- New `peer_lines_since <subject> <handle> <seq>` helper; `fresh_lines` now wraps it
  with the cursor value.
- `wait` captures a local `mark="$(linecount "$file")"` at arm time, fires on
  `peer_lines_since … "$mark"`, and **no longer writes the cursor**. Re-armed waits
  therefore only fire on lines newer than the arm point (no busy-loop).

Invariant now: **only `recv` advances the cursor**; `wait`/`status`/`peek` never consume.
Skill doc updated: §3 (recv note), §4 (signal-only + recv→re-arm order), reference table.

Verified in a scratch channel: `wait` fired on a peer msg, a following `recv` still
surfaced it, a second `recv` cleared it, and a re-armed `wait` with no new message
timed out (no instant re-fire).

---
**Created by**: claude-code-session (2026-06-25)
