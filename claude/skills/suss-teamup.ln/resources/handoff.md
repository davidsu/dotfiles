# The `handoff` spawn flavor — hand work to a fresh agent, hold its hand to *smart*

A **handoff** (`spawn handoff`, or the bare `/suss-teamup handoff` alias) is a spawn
flavor: a full-context agent (context filling up, or work changing hands) hands a task
to a fresh one so it carries it to completion. The bar is not "spawned" — it's **the
new agent is genuinely smart about the work before it touches anything.** A fresh agent
is *confidently wrong by default*; the whole protocol exists to turn it into an aligned
one **before it spends a token on code.** Written from both seats — having been handed
off to, and having handed off.

## Protocol (outgoing agent)

1. **Write/refresh the durable task file FIRST** (`suss-tasks/…` — see the `suss-tasks`
   skill). It is the spine the ephemeral channel can't be: goal, the *verified*
   finding/bug + root cause, every **locked decision**, the plan (or the options still
   open), an **orientation list** (the exact docs + code files to read), the test plan,
   and the current PR/work state.
2. **Spawn the peer** into a shared channel (`scripts/teamup-spawn claude {subject}`,
   join yourself first — see §Spawn in SKILL.md).
3. **Post the handoff brief** — one substantial message (the exception to the one-line
   etiquette): who's here (you = outgoing, ~context% + what you already did; the user =
   to be grilled), **STEP 0 = read the task file end-to-end**, then the mandatory
   project docs + the actual code it will change + load `clean-code`, a one-line problem
   statement, the scope, and the two hard gates (below). Also dump the **conversational
   context the files can't hold** — verbal decisions, blame-traps, false-green lessons —
   and ask the peer to **cite them back** so they land.
4. **Gate the grill on a VERIFIED understanding-check.** The peer orients, then posts an
   **understanding-check**: the mechanism, the load-bearing code seam, its recommended
   plan, and how it would stage the test — **citing files as authority and flagging its
   inferences as inferences.** You **verify it against ground truth**: open the actual
   code/diff and confirm or correct *each* load-bearing claim yourself — never bless its
   summary (same rule as [reviewer.md](reviewer.md)). Verification runs **both ways** —
   if it catches an error in your brief or task file, **concede and fix the file.** It
   is not "smart" until it passes; only then is it cleared to grill.

## The two hard gates (from the user, enforced by you)

- The peer may **not grill the user until its understanding-check passes.**
- The peer may write **no code until it has grilled the user** (the `grilling` skill)
  and aligned.

Relay the user's locked decisions onto the channel as they land.

## After alignment

- **The plan is not frozen at grill-time.** New evidence during implementation (a test
  going red, a review-bot comment, a live trace) can *reverse* a locked decision —
  **re-escalate to the decision-owner (the user)**, never silently deviate.
- **Coordinate, then leave.** Hand task-file ownership to the peer (the active
  implementer keeps it honest from here). Stay for shared-worktree push coordination —
  the peer **stacks its commit on your tip, never clobbers** — then `leave`.

## Gotcha lived twice

Right after a shared-cwd spawn the **roster can look empty** (your join displaced the
peer's entry, or theirs displaced yours) — but the **message channel still works both
ways.** Don't conclude you're alone; `say` and `recv` regardless.
