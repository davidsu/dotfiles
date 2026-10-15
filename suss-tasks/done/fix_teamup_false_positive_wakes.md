closed
# Stop suss-teamup waking agents for messages that aren't there

## Summary

Agents on a teamup channel were repeatedly re-invoked by a finished background
`teamup wait`, ran `recv`, and found `unread=0`. Reported 2026-08-04 by David
("agents tripping over some faulty notification of message arriving"). Diagnosed
with `logs-detective` on channel `message-passing-false-positive`, who had lived
through ~4 occurrences in one session and supplied the taxonomy below with task
IDs. Fixed in `claude/skills/suss-teamup.ln/`.

## Root cause

The harness's only wake signal is **"a background command exited"** — nothing
richer can be delivered. So *every* exit of `teamup wait` reads to the agent as
"a peer spoke", and `wait` had several exits that were not messages.

| class | what exited | why it looked like mail |
|---|---|---|
| 1 (dominant) | a duplicate `wait --timeout 0` printed `already listening` and exited 0 at once | indistinguishable from a real fire; and it *looped*, because the Stop hook's `--require-listener` makes the agent re-arm every turn while nothing told it one was already live |
| 2 | a peer's join/leave `ping` counted as "someone spoke" | a peer that joins and says nothing = a guaranteed empty wake, and it also blocked idle as "unread" |
| 3 | an agent's own guard wrapper around the arm exited after detaching | fixing the double-arm in the *agent* can't work: the wrapper's exit is itself the wake |
| 4 (agent misuse) | `teamup say … && teamup wait … &` in one background call | the `say` finished, so the task exited immediately |

Two more defects surfaced while fixing:

- `trap 'rm -f "$pidf"' EXIT INT TERM` cleaned up but never exited, so a signal
  handler let the listener **resume** — `kill` could not kill a listener at all.
- `say --as {typo}` silently created a roster member for an arbitrary handle
  (`ensure_member`'s self-heal couldn't tell "restore me" from "invent me"), so a
  typo materialised a phantom peer that every live listener got woken by.

## The invariant now enforced

**A `wait` may exit only when something has happened on the channel that this handle
has not already seen.** (First drafted as "something *unread*" — corrected during
review, see WAKE vs UNREAD below.)

- duplicate `--timeout 0` arm **stands by**: blocks, and takes over ownership only
  if the owner dies → arming is idempotent from the harness's point of view
- **WAKE and UNREAD are separate predicates**, which the original code had merged.
  Unread = `say`/`ask`/`ack` only (recv's count, status exit code, statusline markers,
  the Stop hook). Wake = those **plus a join `ping`** — a safety net for a peer that
  joins and then waits to be briefed rather than speaking first (§1/§2 discourage that
  but can't prevent it). A `bye` wakes nobody: a departure isn't actionable, and a
  leaving peer's parting `say` wakes you on its own. The wait labels which case fired:
  `wake: peer-spoke unread=N` / `wake: peer-joined unread=0` / `wake: none reason=…`.
  Consequence to expect: `recv` can list more lines than its own `unread=` count
- `status` now also reports `listener=live|none`, so an agent can check before
  arming instead of wrapping `wait` in a guard script whose own exit wakes it. The
  Stop hook reads that same field instead of stat-ing the pidfile itself, so hook and
  agent can't disagree
- every exit is labelled, including a signalled one (`wake: none reason=killed`) — an
  unexplained background exit is indistinguishable from the original bug
- `leave` does **not** signal its listeners: removing the member file makes owner and
  standby alike exit on their own with a labelled reason, which also removed the
  "signal an innocent recycled pid" hazard entirely
- ownership is claimed by write-then-verify (whoever's pid ends up in the file owns
  it) rather than check-then-write. Deliberately lock-free: a lock file dropped by a
  killed process would leave a channel with no possible owner, which is worse than the
  rare double-wake a lock would prevent. This **narrows** the double-claim window
  rather than closing it — A can write-and-verify before B writes, and both then
  believe they own (named by `diff-reviewer`; costs one duplicate wake, self-heals)
- `leave` removes the member file BEFORE appending the `bye`: the bye is what wakes the
  listeners, so the old order let one check membership in the moment before the file
  was gone and block on until some later message
- `listener_is_alive` also requires the pid's command line to be a `teamup wait`, so a
  recycled pid can't make standbys defer forever to an unrelated process
- an idle listener defers `CONFIRM_DELAY` and re-checks before firing, so a
  foreground huddle `wait` racing it on the same channel event normally wins and
  the agent gets one wake, not two
- new `.woken.{handle}` high-water file: a re-armed wait can't re-fire on the
  message that just woke you, in the window before you `recv`
- a bounded (foreground/huddle) wait ignores the pidfile, always fires, and marks
  what it delivered woken — so the armed listener won't wake you for it again
- every listener exits when its member file disappears — the only thing that reaches
  a standby, which holds no pidfile
- `INT`/`TERM` route through `exit`, so listeners are killable at all (see defects)
- `ensure_member` restores only, never invents: an unseen handle is refused with
  "run join"

### Residuals (documented in SKILL.md, not fixable here)

- a message landing mid-turn fires the listener at once, but the exit is reported
  only after the turn ends — so if you `recv`d it at a checkpoint, that wake arrives
  empty. Hence the standing rule: **`recv` before believing a wake; `unread=0` means
  carry on**
- the harness wakes on **any** background command exiting, teamup or not
- ownership handoff has a ~2s gap: after a fire the Stop hook may ask for a listener
  that a standby is about to claim. Cost is one extra standby, never a loop
- a running `wait` keeps the code it started with, so upgrading `teamup` leaves live
  listeners on the old behaviour — and they hold the pidfile, so a correct new arm
  stands by behind them. Restart them to pick up a change
- a bounded `--timeout` exit is by definition an exit with nothing to read, so
  bounded waits are **foreground-only** now — stated in §2 and §4

## Review round (logs-detective, same channel)

It reviewed the design before I coded and raised six holes. Outcome:

1. **Ping/bye must still wake — mutual-idle deadlock.** Directionally right, and it
   later partly retracted the strength of it (a doc-following joiner always speaks, so
   the deadlock needs a *non-compliant* peer — a safety net, not a structural need).
   `diff-reviewer` then argued `bye` should not wake at all, which both agreed to.
   Taken: wake and unread split into two predicates, join wakes, bye doesn't.
2. **Timeout exit unaddressed.** Correct: §2 recommended `--timeout 110`, which
   backgrounded reintroduces the bug. Taken as a doc rule (foreground-only).
3. **Exit predicate must be a conjunction (`> cursor` AND `> woken`), and `recv`
   must never advance the woken mark.** Already how it was implemented; confirmed.
4. **The phantom guard contradicts documented presence self-heal.** Applies to my
   design *message*, not the code: the guard keys on "has this handle ever appeared
   on the channel", and a `leave` leaves its `ping`/`bye` in the log — so a resumed
   agent's lone `say` still restores it (regression-tested). Added its narrower
   suggestion too: a handle equal to an existing channel name is refused outright.
5. **"Never chain anything before wait" overstates.** Correct: `cd X && wait` is the
   same process and safe; the trap is anything that *spawns* and returns (`nohup … &`)
   or is chained after. Doc reworded.
6. **Handoff race.** Real; mitigated (poll 5s→2s) not eliminated, documented above.

Its request for an observable listener state became `status`'s `listener=` field.

## Files

- `claude/skills/suss-teamup.ln/scripts/teamup` — `wait` rewrite, `spoken_only` /
  `worth_waking_for` / `unwoken_lines` / `record_woken` / `listener_is_alive` /
  `claim_listener` / `leave_channel` helpers, `ensure_member` guard, `listener=` in
  `status`
- `claude/skills/suss-teamup.ln/scripts/teamup-hook` — reads `listener=` from `status`
  instead of stat-ing the pidfile; arm instructions say "bare, nothing chained"
- `claude/skills/suss-teamup.ln/SKILL.md` — §4 rewritten (idempotent arming, the
  two rules for an honest wake), reference table, limitations

## Verification

26-case regression suite, all green (run repeatedly), at
`/private/tmp/claude-501/-Users-davidsu--dotfiles/72744810-833c-48fa-bc72-0603576d9d51/scratchpad/tu-test.sh`
(runs against an isolated `SUSS_TEAMUP_DIR`; ~1 min). Covers each class above plus
the huddle path, the re-arm loop, leave-kills-standby, and the phantom member.
Not yet copied into the repo — no test harness exists for the skill's shell
scripts yet; decide whether it belongs somewhere permanent.

`logs-detective` re-tested independently: suite green on its machine, and across six
real wakes on two live channels with three peers it recorded **zero** empty
notifications — every wake self-described and every count was exact, including one
case that looked like a discrepancy until inspected (a wake said `unread=2`, the recv
seconds later said `unread=3` and printed four lines: one more message had landed, and
the fourth line was a ping shown as context but not counted — the intended split,
confirmed live). It also confirmed the trap fix operationally: a new listener dies in
1s on plain SIGTERM, where a pre-fix one survived 10s and needed `-9`.

`diff-reviewer` reviewed the working-tree diff and ran a 5-round race probe: the
foreground huddle wait beat the armed listener 5/5, so `CONFIRM_DELAY` does its job.

The two behaviours that needed a real join/leave to see (rather than the suite) were
confirmed by driving a second handle from one session, each in a turn with no
accompanying message — any `say` in the same turn gets folded into the same wake and
destroys the isolation, which defeated two earlier attempts:

- **`bye` never wakes** — the peer's listener stayed blocking through the departure
  (30s of separation, so no timestamp collision to explain it away), its pidfile
  verified live from the other side rather than taken on its word. Confirmed twice, the
  second time on an unplanned departure whose wake payload named only the two `say`s
- **`wake: peer-joined unread=0`** — a silent join fired that exact label with only the
  ping line. Caught by **two independent listeners in two sessions**, each reported
  before reading the other's

`recv`'s count/display split was independently re-confirmed three times: a wake saying
`unread=2` followed by a `recv` printing three lines, the third being a ping as
context. Expect that; it is the design.

### What the collaboration actually contributed

Worth recording, because both testers said it about themselves before I could: the
half of this loop that held up was **evidence** — the class taxonomy read out of real
task-output files, the live T1/T3 runs, the race probe, and reading the diff instead of
my summary of it. The half that needed correcting was every time any of us reasoned
past the evidence: the mutual-idle deadlock was overstated, the `mkdir` lock and the
`pkill -9` sweep were both wrong, a reported "count vs display inconsistency" was my
own uncommitted edit, and my own claim that write-then-verify closes the double-claim
race was false. Findings from artefacts survived; findings from inference didn't.

### Method hazard worth remembering

Both testers reach the script through `~/.claude/skills/suss-teamup`, which symlinks
into this repo — so a tester on a live channel always runs whatever is on disk *right
now*. During an edit session neither side can distinguish a behaviour change from a
defect, and one reviewer spent real effort on a "count vs display inconsistency" that
was simply an edit landing between its two measurements. If this is done again,
announce edit start/finish on the channel so observations can be timestamped against
it.
