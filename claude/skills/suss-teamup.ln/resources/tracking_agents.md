# Leading several agents

How a lead runs a job split across several agents: one owner per unit of work (a PR, a
feature, a bug), plus helpers such as a tester or a reviewer.

## One tracking file

Keep one task file (`suss-tasks` skill) with a row per unit of work. Each unit's owner adds
its row when the work starts, keeps it current, and removes it when the work is merged or dropped.

| Column  | Holds                                                                         |
|---------|-------------------------------------------------------------------------------|
| unit    | what it is, named the same way everywhere (titles, task files, messages)      |
| link    | the PR, task or ticket                                                        |
| owner   | the agent's handle                                                            |
| resume  | `cd <dir>; cyc --resume <session id>`, so the lead or the human can wake it   |
| status  | exactly one state from a fixed list, e.g. `in progress` · `waiting for review` · `approved` · `merged` · `blocked on <what>` |

Each unit also has its own task file for its detail. The lead keeps one more file for the
state of the whole job: what changed, what's next, and a "waiting for the human" table, so
the human finds every decision they owe in one place. Its rows are numbered, and a number is
never reused or dropped: an answered row is marked answered, so the human can tell nothing vanished.

## Briefing an agent

A brief starts the agent's work, so it carries everything it needs:

- **the job**, in one or two sentences, and who it reports to
- **what to read first**, in order: the tracking file, its unit's task file, the rules
- **the steps**, and what NOT to do (no posting, no merging, no scope changes without asking)
- **the end condition**: what "done" looks like, then "say ready to sleep"
- **failure rules**: e.g. CI failed on infrastructure → rerun once, then report; never wait silently

Ask for a plan, or an understanding-check, before it writes code; for a hand-off use
resources/handoff.md. **Don't decide in the brief what isn't decided.** A brief that hands
the agent a conclusion ("agree with the reviewer that…") gets that conclusion repeated back
even where it's wrong. Hand it the question and the sources.

## Limits

- **Few units in flight at once.** Two works well; the human may raise it. A unit waiting
  for review doesn't count.
- **Close what you open.** An idle agent tab and every browser tab use memory. Agents
  close their browser tabs when a check is done; the lead sweeps leftovers.
- **Context**: at about 60% of its context, an agent (the lead too) hands off to a fresh one
  (resources/handoff.md).

## The lead's loop

- **Every wake**: `recv` (never discard its output), act on what arrived, re-arm the listener.
- **Keep a timer** (e.g. a cron every 30 minutes) running a fixed list of checks: open review
  comments, CI results, agents that went quiet. Never idle while a check could move work.
- **"Done" means nothing is left that an existing rule covers.** Recheck the list before
  saying the queue is empty.
- **Silence → ask.** An agent that hasn't reported in a while gets a status ask.
- **Check the roster before relaying.** An agent that isn't on the channel won't see the message.
- **After spawning or waking, check the roster.** A launch can fail silently.
- **Announce before typing into another agent's tab**, and prefer channel messages to keystrokes.
- **Verify, don't relay.** Before passing on an agent's claim, check it in the code, the PR or the log.

## Decisions and the human

- **Name one source of truth** for the job (a spec, a design file, a reviewer) and let it
  settle doubts. When something is unclear, log it in the tracking file and move to other work.
- **Don't invent approval steps.** Work an existing rule already covers goes ahead without
  asking. An approval step the human didn't ask for stalls the whole team while they're away.
- **A one-off instruction is not a rule.** "Don't wait for my OK on this one" applies to that
  one; don't write it into the rules.
- **Escalate only real decisions**, and put them where the human can answer from a phone: the
  Slack thread, not an agent's terminal.
- **Check outward-facing text against the human's own words**, not your reading of them,
  before it goes out.
- **Don't keep editing a reply a person already got.** Each edit notifies them again with the
  new text; fix it once, or post a correction.
- **Have outward-facing messages reviewed.** An independent reviewer agent that audits what was
  posted to people (PR replies, Slack) catches mistakes before they embarrass anyone.
