# The `handoff` spawn flavor — hand work to a fresh agent, hold its hand to *smart*

A **handoff** (`spawn handoff`, or the bare `/suss-teamup handoff` alias) is a spawn
flavor: a full-context agent (context filling up, or work changing hands) hands a task
to a fresh one so it carries it to completion. The bar is not "spawned" — it's **the
new agent is genuinely smart about the work before it touches anything.** A fresh agent
is *confidently wrong by default*; the whole protocol exists to turn it into an aligned
one **before it spends a token on code.** Written from both seats — having been handed
off to, and having handed off.

**A lead handing off** keeps the protocol below but first puts a temporary lead in its seat:
[A lead hands off](#a-lead-hands-off-a-temporary-lead-first).

## Protocol (outgoing agent)

1. **Write/refresh the durable task file FIRST** (`suss-tasks/…` — see the `suss-tasks`
   skill). It is the spine the ephemeral channel can't be: goal, the *verified*
   finding/bug + root cause, every **locked decision**, the plan (or the options still
   open), an **orientation list** (the exact docs + code files to read), the test plan,
   and the current PR/work state.
2. **Spawn the peer** into a shared channel (`scripts/teamup-spawn claude {subject}`,
   join yourself first — see resources/spawn.md). Leave out `--role` and `--color`: the
   successor takes your color, so the user still sees the PR owner, lead or keeper.
3. **Post the handoff brief** — one substantial message (the exception to the one-line
   etiquette): who's here (you = outgoing, ~context% + what you already did; the user =
   to be grilled), **STEP 0 = read the task file end-to-end**, then the mandatory
   project docs + the actual code it will change + load `clean-code`, a one-line problem
   statement, the scope, and the two hard gates (below). Also dump the **conversational
   context the files can't hold** — verbal decisions, blame-traps, false-green lessons —
   and ask the peer to **cite them back** so they land. **Address it to the peer**
   (`ask --to {handle}` or open with `@{handle}`), and have the peer address its replies
   to you: on a channel with 3+ agents an unaddressed message wakes nobody (resources/listening.md).
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

## A lead hands off: a temporary lead first

The lead's own duties: [lead_role.md](lead_role.md). A lead busy handing off is a lead David can't reach (David, 2026-10-15: "Yesterday i needed
my lead's attention urgently in slack (Guy Ofeck dm) but he was too busy handing off and being
available to the teams"). So a lead never hands off directly: a **temporary lead**,
`lead.temp.{x}` (`x` = the outgoing lead's number: lead.24 → `lead.temp.24`), holds the seat
for the handoff window.

**What lead.temp.x covers, nothing else:**
- David on `#suss-lead`: it acks every top-level line with `--top` and acts on it, as the lead would
- the teams' channels: answers their asks, routes their reports, keeps their gates

It takes no part in the handoff itself, starts no new work, and leaves the handoff file to
the outgoing lead.

**The window file** is lean, beside the handoff file in the same task directory:
`handoff_{old}_to_{new}_temp_window.md` next to `handoff_{old}_to_{new}.md`. It says what
happened in the window that the new lead needs: David's asks and what was done, team
reports, anything still open. Possibly just "nothing noteworthy".

**Protocol** (David's order, 2026-10-15):

1. The lead updates suss-tasks.
2. The lead prepares the handoff file.
3. The lead spawns lead.temp.x into `suss-lead`, brief first (`--as lead.temp.{x} --role lead`).
   The brief lists every team channel; lead.temp.x joins each one and arms a listener on it.
4. lead.temp.x pings "ready" on `suss-lead`.
5. The lead yields: on `suss-lead` and on every team channel, "lead.temp.x has the seat until
   the new lead is ready". From here it answers only its successor.
6. The lead updates the handoff file if needed.
7. The handoff protocol as above: spawn the new lead (no `--role`: it takes the lead's color),
   brief, verified understanding-check.
8. The new lead pings "ready".
9. lead.temp.x yields, on `suss-lead` and on every team channel.
10. The new lead acks and takes over.
11. lead.temp.x delivers its window file (pushed) and says its path on `suss-lead`.
12. The old lead goes to sleep if still awake; lead.temp.x goes to sleep
    (`scripts/teamup-sleep --force`, no argument).

## Gotcha lived twice

Right after a shared-cwd spawn the **roster can look empty** (your join displaced the
peer's entry, or theirs displaced yours) — but the **message channel still works both
ways.** Don't conclude you're alone; `say` and `recv` regardless.
