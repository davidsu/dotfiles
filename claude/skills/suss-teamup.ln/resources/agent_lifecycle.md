# Waking agents up and putting them to sleep

An idle agent tab costs memory, so an agent whose work is done, or that is only waiting on
someone, is **put to sleep**: its tab is closed. It is **woken** later by resuming its
session, with its full context, in a new tab. Both are claude-on-iTerm only.

```
S=~/.claude/skills/suss-teamup/scripts
$S/teamup-sleep [--force] <handle>...        # leave its channels, close its tab
$S/teamup-wake --list                        # who can be woken
$S/teamup-wake <handle> [--channel C] [--color COLOR]
```

## Putting an agent to sleep

1. **The agent prepares, then says it is ready.** Before it may sleep it must:
   - commit and push everything (code and its task file), and say the commit on the remote
   - close every browser tab and browser session it opened, and stop any loop or timer it started
   - say on the channel `ready to sleep`, with its state in a line or two
2. **Whoever sleeps it verifies first.** Check the pushed commit and the task file yourself
   (`git log origin/…`, the file on disk). Never take "done" on the agent's word.
3. Run `teamup-sleep <handle>`. It `leave`s every channel, which records how to resume the
   agent, and closes the iTerm tab titled `<handle> (claude)`. It refuses while a peer is
   waiting on the agent's answer or the agent spoke in the last minute (it may be mid-push),
   and prints what the agent last said; `--force` overrides.

An agent goes to sleep as soon as it is waiting on a reviewer, a human or another agent.
Don't keep it open to babysit; wake it when the thing it waits for happens.

## Waking an agent

1. `teamup-wake <handle>` resumes the session in its own directory and has it rejoin its
   channel. It refuses if the session is still running: a session must never run twice.
   `--color` colors the tab only; it never types into the agent's tab, where keystrokes can
   collide with the user's.
2. Wait for it to print `back on '<channel>'`. A brief posted before the agent rejoins is
   easily missed.
3. **Brief it on the channel**, `ask --to` it:
   - one job; the exact trigger (the commit, run, comment or message that changed)
   - what to do, and what NOT to do
   - the end condition, usually "then say ready to sleep"

   On rejoin the agent already sees what was aimed at it while it slept, so the brief can
   point at those messages instead of repeating them.
4. Confirm it took the brief (an `ack`, or its plan) before you count it as working.

After quitting iTerm, `teamup-wake --list` shows everyone the session-end hook recorded;
wake each one you need. Agents that ended for good just stay on the list.

## Where the resume information comes from

Every `leave` (by hand, `teamup-sleep`, or the session-end hook) records the agent's
session id, directory and channels in `~/.local/state/suss-teamup/parked.tsv`, and the next
`join` clears it. A lead that tracks agents should still keep each agent's resume line,
`cd <dir>; cyc --resume <session id>`, in its tracking file (resources/tracking_agents.md):
the record lives on one machine, the tracking file is shared and durable.

A session that crashed never left, so it has no record; `teamup-wake` then falls back to
the channel registry, which still holds its session id. Only claude sessions can be woken.
An agent can read its own session id from `$CLAUDE_CODE_SESSION_ID`.

`ask --to <handle>` refuses when that agent isn't on the channel (exit 3) and names the
`teamup-wake` command, so a question never lands on an empty seat.
