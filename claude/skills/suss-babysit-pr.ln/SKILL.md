---
name: suss-babysit-pr
description: >
  Babysit a pull request to green: poll its CI and review-bot comments on a
  4-minute interval, fix or rerun red CI, and answer review-bot comments —
  fixing+resolving the reasonable ones and pushing back+resolving the wrong
  ones. Invoke manually with /suss-babysit-pr when you want an open PR shepherded
  toward merge without ruining a good PR over out-of-place bot nits.
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Babysit a Pull Request

Shepherd one open PR toward a clean, mergeable state: keep CI green and keep the
review bots answered, without letting a creative bot comment damage a good PR.

## 1. Find "the PR"

Usually you already know which PR is meant — the one under discussion this
session. If not, it's the pr for the worktree in which you are working (or pwd if that's your working dir)

If still ambiguous (multiple plausible PRs, no branch match), **ask the user**
which PR — do not guess. Lock onto one PR number for the rest of the loop.

## 2. Poll loop (every 4 minutes)

Each cycle does **CI check** then **comment check**, then waits ~4 minutes and
repeats. Two ways to run the cadence:

- Preferred: the user runs `/loop 4m /suss-babysit-pr` — each fire is one cycle.
- Self-paced: after finishing a cycle, schedule the next wake-up ~4 minutes out
  (240s) and repeat. Do **not** busy-wait with a foreground `sleep`.

**Stop the loop** when: the PR is merged or closed, CI is green _and_ every bot
comment is resolved(or escalated), or the user says stop. Report the terminal state and exit.

## 3. CI is red → fix or rerun

- **Real failure** (your change broke something): fix it, commit, push to the PR
  branch. Re-read the failing test/log first — do not paper over it.
- **Flaky / infra** (timeout, network, known-flaky test, runner died): rerun
  rather than "fix".

## 4. Bot review comments → judge, then act

Fetch unresolved review threads
For each unresolved bot comment, decide:

- **Repeat of previously resolved comment** -> new commits trigger new loop,
  bot often wrongly complain about the same thing. if it's repeated then reply
  with link to the original question/answer and mark resolved.
- **Obviously right and reasonable** → fix it, reply briefly noting the fix
  (commit it with the rest), mark the thread resolved.
- **Obviously wrong** → reply explaining why it's wrong, mark resolved. Do not
  change the code.
- **Unsure / high-stakes** → escalate to the user; leave it unresolved.

### Don't ruin a good PR

Review bots are creative and narrow. Watch for these and push back instead of
complying:

- Asking for elaborate handling of an edge case that's better left to error out
  loudly.
- Flagging a case that **can't actually happen** because of an invariant
  enforced elsewhere (the bot only saw a slice of the system and lacks the
  holistic view — the guarantee is "X-far" from what it read).
- Style/over-engineering nits that add complexity for no real-world benefit.

When you push back, say _why_ (cite the invariant, the caller, the design
choice). A confident, correct rejection is better than a defensive code change
that complicates a clean PR. **Escalate freely** — it's cheaper to ask than to
degrade the PR.
