# Waking agents up and putting them to sleep

An idle agent tab costs memory, so an agent whose work is done, or that is only waiting on
someone, is **put to sleep**: its tab is closed. It is **woken** later by resuming its
session, with its full context, in a new tab. Both are claude-on-iTerm only.

```
S=~/.claude/skills/suss-teamup/scripts
$S/teamup-sleep [--force] [<handle|id>...]   # leave its channels, close its tab; no argument: yourself
$S/teamup-wake --list                        # who can be woken
$S/teamup-wake --asleep <handle>             # exit 0 if it can be woken
$S/teamup-wake <handle|id> [--channel C] [--role ROLE] [--color COLOR] [--after HANDLE]
```

## Putting an agent to sleep

1. **The agent prepares, then says it is ready.** Before it may sleep it must:
   - commit and push everything (code and its task file), and say the commit on the remote
   - close throwaway browser tabs it opened (`browser_tabs close`, `[Welcome]` included; see `/suss-browser`), and stop any loop or timer it started
   - say on the channel `ready to sleep`, with its state in a line or two
2. **Whoever sleeps it verifies first.** Check the pushed commit and the task file yourself
   (`git log origin/…`, the file on disk). Never take "done" on the agent's word.
3. Run `teamup-sleep <handle>`. It hangs up the agent's claude by pid (SIGHUP, what a tab
   close delivers: the session ends through its SessionEnd hooks, which `leave` its channels
   and record how to resume it), waits for the process to exit, `leave`s whatever is left,
   and closes its iTerm tab. The tab is closed last on purpose: iTerm's "Undo can revive a
   closed session" keeps a closed tab's process alive for ~5 s (profile default), so closing
   first left the agent running, and taking turns, after the tool had said `closed`. It
   refuses, and says why, while:
   - the agent's tab has keyboard focus (the current tab of iTerm's front window): David is
     looking at it
   - David messaged it in the last 5 minutes: a prompt typed in its terminal (the last
     `origin.kind == "human"` turn of its transcript, not counting the `/suss-teamup` that
     spawn and wake type), or a channel message from `david` naming `@<handle>` (which
     includes `ask --to <handle>`)
   - a peer is waiting on the agent's answer
   - the agent spoke in the last minute (it may be mid-push)

   It prints what the agent last said. `--force` overrides, and still prints the reasons.

   A target is a handle or a claude session id. An agent sleeping itself passes neither: the
   script takes `$CLAUDE_CODE_SESSION_ID`. A session on no channel is found through
   `~/.claude/sessions/{pid}.json` (its session name and cwd), and parked so `teamup-wake` resumes
   it without a channel to rejoin.

An agent goes to sleep as soon as it is waiting on a reviewer, a human or another agent.
Don't keep it open to babysit; wake it when the thing it waits for happens.

## Waking an agent

**Post the brief first, then wake.** The agent sees the brief the moment it rejoins, so
nobody waits on an "awaiting lead" round trip.

1. **Brief it on the channel**, `ask --to` it, while it still sleeps:
   - one job; the exact trigger (the commit, run, comment or message that changed)
   - what to do, and what NOT to do
   - the end condition, usually "then say ready to sleep"

   `ask` queues it and prints `queued for <handle> (asleep)` with the wake command. On
   rejoin the agent sees everything aimed at it while it slept, so the brief can point at
   those messages instead of repeating them.
2. `teamup-wake <handle> [--channel C]` prints what is waiting for the agent on the channel
   (`unread=N asks_for_me=M`), then resumes the session in its own directory, in a tab
   immediately right of yours (or of `--after HANDLE`'s, see spawn.md → Tab position), and has it
   rejoin that channel. It refuses if the session is still running: a session must never run twice.
   It gives the tab and `/color` the `--color`, else the `--role`'s color
   ([known_team_roles.md](known_team_roles.md)), else the color the agent had before it
   slept. `/color` is typed into the new tab until the transcript records it; if the agent
   never comes up, wake says so and exits 1. The usual cause is a permission prompt the
   resumed session is stuck on.
3. Wait for it to print `back on '<channel>'`.
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
the channel registry, which still holds its session id. The registry lives in `/tmp`, so
after a reboot a crashed session can be woken only from the resume line in the tracking file:
that is why the tracking file keeps one. Only claude sessions can be woken.
An agent can read its own session id from `$CLAUDE_CODE_SESSION_ID`.

`ask --to <handle>` to an agent off the channel is queued only when it was on this channel
and `teamup-wake` can resume it. Any other absent handle is refused (exit 3): a typo or an
agent that can't come back would leave the question on an empty seat.
