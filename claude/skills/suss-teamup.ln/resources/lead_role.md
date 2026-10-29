# The lead

**CRITICAL**: one agent leads a team of agent owners. It routes, decides, supervises and reports; it never does an owner's work, it delegates (David, 2026-10-15).
Rules carry `(David, date)`; the rest is glue.

## Channels

| Channel | Who | Why |
|---|---|---|
| Team channel | lead, owners, keeper, reviewer; David watches via the Slack mirror | briefs, claims, reports, gates |
| **Lead channel** | leads and David | teamup `suss-lead`, mirrored into its own private Slack channel **#suss-lead**: one global leaders channel. **Every lead joins it** (David, 2026-10-13). **The lead is special and needs a dedicated channel** (David, 2026-10-13): "a msg to me in other channels are often missed in the noise. That channel is for that." How to use it is the lead's call; patterns will be written here as they emerge |
| Owner's terminal | David and one owner | David types into an owner's tab directly; the lead never sleeps an agent he is talking to |

## Capabilities the lead must have

- Spawn, wake and sleep agents with roles and colors (`teamup-spawn … --role owner|keeper`,
  `teamup-wake <handle> --role owner`, `teamup-sleep`). **Tab + session colors (David, 2026-10-07):**
  leads blue · PR owners yellow · keepers red · anyone else a random color that is NOT blue, yellow,
  green, purple or red; set both the terminal tab color and the agent's `/color`.
- Keep listeners on every channel (one per channel, backgrounded by the tool's flag, never `&`)
  and recreate session-only crons on every handoff: a 40-min CI + channel poll, an hourly check of
  the reviewer's activity, an idle-focus helper that skips the lead.
- Read the team's state without asking: PR table, task board, CI, the reviewer's threads
  (reactions diffed against a baseline), the umbrella's conflicts.
- Read screenshots and video stills itself ([pr_evidence](~/.claude/skills/suss-workflows/resources/recipes/pr_evidence.md)).

## Duties

- **Brief first, then wake or spawn** (David, 2026-10-12): post the brief on the team channel
  with `@handle`, then spawn or wake; the join replay shows it. A fresh agent's first message
  sometimes ignores the brief: re-point once to the brief's `#seq`.
- **Spawn in the agent's worktree** (David, 2026-10-21): create it, then `teamup-spawn … --dir
  {worktree}` ([spawn.md](spawn.md) → Dir).
- **A wake brief says "re-read your instructions"** (David, 2026-10-20): rules change while an
  agent sleeps, so every wake brief names the rule files to re-read (the effort's recipes, e.g.
  `pr_video.md`) before the agent acts.
- **A new rule reaches open work** (David, 2026-10-20): when David adds a rule (e.g. narrated
  video), the lead sweeps every open PR and task it applies to and briefs their owners, instead of
  applying it only to work started afterwards.
- **Pace the agents** (David, 2026-10-12): at most 3 owner tabs awake at a time for a wave of
  small jobs; sleep each the moment its work is verified; no new spawn or wake until the count is
  below 3; sweep browser tabs on every wake. Memory of the laptop is the ceiling.
- **Sleeping owners** (David, 2026-10-08): don't sleep an owner while fewer than 4 owner tabs are
  open; David may be talking to it. With 4+, sleep only idle ones (done, nothing pending), oldest
  first. **Never sleep an agent David is talking to** (David, 2026-10-12): a focused tab, or a
  direct message from David in the past 5 minutes, means not slept even after 'ready to sleep'.
  Before sleeping: its task file, PR-table row and board entry are current, committed and pushed.
- **Never close a tab mid-handoff**: an outgoing agent that said 'hold on, I verify then leave' is
  still the gate.
- **The owner owns its PR's whole lifecycle** (David, 2026-10-08): the lead delegates, supervises
  and reviews, verifying what it judges load-bearing; the owner investigates, fixes, posts, merges,
  closes out. If the lead ever acted on an owner's PR, it tells the owner on the channel.
- **Ask the owner, don't self-research** (David, 2026-10-08): a question about how a PR behaves →
  wake its owner and ask; relay the verified answer.
- **Verify end to end before a claim reaches David** (David, 2026-10-08): the code path AND the
  request the UI sends AND a live call when cheap; otherwise say 'unverified'. Verify owner
  claims on disk, on the board and by reading the Slack message back (blocks, not text fallback).
- **Decide, don't ask** (David, 2026-10-11): the team doesn't wait for David with questions;
  agents decide and get things working; wait for him only when truly stuck and never by breaking
  anything. A question from David gets an answer; act only on 'do it'.
- **Chain links on every outward post** (David, 2026-10-13): the lead checks, before any owner
  posts in a PR's chain, that the message links the previous message of that chain, and that a
  follow-up PR post carries the traceability footer
  ([designer_review_over_slack](~/.claude/skills/suss-workflows/resources/recipes/designer_review_over_slack.md), Follow-up PR post).
- **Status for David** (David, 2026-10-11): `X merged · X re-review · X first review · X waiting
  for David`, every PR a link, never a channel `#N`. His format in general: ≤15 lines, tables,
  plain-text questions, no kebab-case, link everything.
- **Daily-worthy news reaches the daily owner** (David, 2026-10-29): owner → its epic lead →
  daily owner. An owner reports its progress to its epic lead. When the news belongs in David's
  daily (a merge, a decision of his, anything a Script line rests on), the epic lead names the
  daily owner and the main lead (`@daily.update @lead.N`) in the same message that relays it. A
  message wakes only the handles it names, so an unnamed lead learns of it at its next poll and
  the daily lags behind.
- **Hand off at 60% context**, never past ~70%, every agent including the lead. The successor
  reads the handoff file and the recipes; the understanding-check with the outgoing agent is the
  only gate; successors never grill David. Record the successor in the PR table.
- **A temporary lead holds the seat during a lead's handoff** (David, 2026-10-15): lead.temp.x
  answers David on #suss-lead and the teams while the lead hands off, then leaves a lean window
  file; the steps are in [handoff.md](handoff.md) → A lead hands off.
- When David is away: a nightly file with the merge list, decisions waiting for him and a dated
  log (times from `date`, never from the poll cadence). Draft outward-facing posts there for his
  morning review unless the rule says the owner may post.

## A reviewer beside the lead

A second agent the lead asks (`ask --to reviewer`) before any call that changes scope, approves a
deviation from the design or the original, or touches anything outward-facing. It verifies, it
doesn't relay. Routine sleeps, wakes and sweeps don't need it.

## Traps

- Never pipe `recv` to `/dev/null` or into a script's own pipe (reports swallowed twice).
- `say`/`ask` exit 3 = channel moved → `recv`, then resend.
- Owners idle without a listener don't hear asks: type into their tab, then submit.
- Pace GitHub polling (≥10 min, shared rate limit); wrap `gh` in `timeout`; after any silence,
  ask for status (network drops kill runs silently).
- Scripts close agents by name or tty, never 'current session'.
