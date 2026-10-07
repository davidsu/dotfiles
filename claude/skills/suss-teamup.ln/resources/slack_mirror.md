# The Slack mirror

The mirror is the only Slack posting teamup does. A message an agent writes *directly* to a
Slack channel or thread for people (PR nudges, review replies) is not channel traffic: it
follows the `suss-slack-post` skill. Channel messages themselves stay plain one-line text.

Every channel is mirrored into a **Slack thread automatically** — `join` starts the
bridge (SKILL.md → Join, `mirror_to_slack_unless_bridge`), so the user can pick a channel up on a
phone without anyone having armed anything first. One thread per channel name, reused
across restarts, reboots and `erase`: the thread state (`{subject}.thread`, `.posted`,
`.relayed`, `.engaged`, `.url`) lives in `~/.local/state/suss-teamup/slack/`, not in the
ephemeral channel dir — when it lived there, a recreated channel opened a fresh thread and
the user kept replying into the old, unpolled one. The bridge retires itself once the
channel has had no real member for 2 minutes (a single empty poll used to kill it during
an agent's leave/re-join). Replies typed while no bridge runs are not lost: the next
bridge for that channel relays every reply it has not relayed yet. **Nothing to invoke**
— the manual controls exist only for overriding it:

```
scripts/teamup-slack status          # which channels are mirrored
scripts/teamup-slack off [subject]   # stop mirroring (bare: all channels)
scripts/teamup-slack on  [subject]   # re-start one you turned off
```

**Finding a channel's Slack thread** — never reconstruct a permalink from `.slack.thread`:
the bridge announces it on the channel (`mirror thread in Slack: <url>`) the first time a
mirror opens, writes it to `~/.local/state/suss-teamup/slack/{subject}.url`, and
`scripts/teamup-slack url {subject}` prints it (creating + announcing it if missing).

**A running poller keeps the code it started with.** Restart it (`off` then `on`) only
when the edit touched a path the live loop executes — `deliver_to_channel`,
`mirror_channel_to_slack`, `post_to_thread`, the poll loop. `claim_mirror` and the docs
are start-path only, so they need nothing. Stopping a bridge also kills its `teamup wait`
— an orphaned one used to keep the listener pidfile, wake on the next message, mark it
seen and exit, so the restarted bridge never posted it. A bridge killed after its script
was edited may log a syntax error on its way out (bash reads the script lazily);
harmless. Sweep what is live and how stale it is:
`for p in "$SUSS_TEAMUP_DIR"/*/.slack.pid; do pid=$(cat "$p"); kill -0 "$pid" 2>/dev/null && echo "$p $pid $(ps -o lstart= -p "$pid")"; done`

**suss-tasks mirror** — `scripts/teamup-tasks-sync` (run on demand) uploads every active
task file (`~/projects/*/suss-tasks/**/*.md`, `done/` excluded) into the same Slack
channel: one `suss-tasks · {project}` thread per project, each file titled
`{project}/{relpath}` with its local path as the first line. Idempotent by content hash;
changed files replace their superseded upload, locally deleted files are removed. This is
the context Slack-side readers (the user's phone, Claude-in-Slack) have for the team's
work — re-run it after meaningful task-file changes. Claude-in-Slack cannot clone the
private suss-tasks repo, so its channel instructions (set on the configure page
https://claude.ai/claude-in-slack/T08EJMFT8LD/C0BU8PNU5AQ/configure, not stored here) only
say: read these snapshot threads, and ask an agent in the teamup thread to post a task
file when it is missing or stale.

**Residual (documented, not fixed):** `claim_mirror` clears a dead pidfile and then
`noclobber`-creates its own, and it verifies afterwards that its pid is the one that
landed — so a loser backs off. Two joiners whose writes straddle the other's verify can
both believe they claimed; cost is one duplicate relay until an `off`. Same TOCTOU class
as `claim_listener` above, and not worth a lock.

`TEAMUP_SLACK=off` disables auto-mirroring entirely. A machine with no Slack session in
its keychain silently gets no mirror — auto-start never speaks and never fails, so it
cannot break `join`.

It is **deterministic plumbing — no model in the loop**, so it costs no turns and no
context, and it keeps working while every agent is mid-turn or wedged (unlike the Stop
hook, which only fires *between* turns). It joins as a normal member
(`$TEAMUP_SLACK_HANDLE`, default `david`) and reuses teamup's own delivery both ways:

- **out** — `wait --timeout 0` (fswatch, free) → `recv` → one `chat.postMessage` per
  channel message in the thread. Batching a wake's messages into one code block hid
  answers inside a wall of text on a phone.
- **in** — `conversations.replies` → `say`, or `ask --to {handle}` when the reply starts
  with a **live** handle (`@` optional, `.` and `-` interchangeable: `lead.7 do X` aims at
  `lead-7`; the user is often on a phone keyboard), so an aimed reply wakes one agent and trips its Stop hook
  (`asks_for_me=1`) instead of waking the roster. A name no member holds is delivered to
  everyone and answered in the thread with the live handles — aiming at nobody used to
  become a dangling ask. Aiming is **not privacy**: every message lands on the shared
  channel and all agents read it; it only decides whose idle is blocked.
- **attribution** — the bridge posts under one handle, so a thread reply from anyone but
  the channel owner is prefixed `[slack: {name}]` (from `bot_profile.name`/`username`,
  else `users.info`). Without it, @Claude's replies arrived on the channel as the user's.

**It cannot loop.** Outbound, `recv` never returns this handle's own lines (`$3!=me`,
`teamup:234`), so anything injected from Slack can't be posted back. Inbound, every
message the bridge posts is recorded in `.slack.posted` and skipped on read — needed
because a user-session token posts as the user, so bridge posts and phone replies share
one author. Both directions are exact, no heuristics.

**Auth is the user's Slack web session** — the same `slack-mcp-xoxc` / `slack-mcp-xoxd`
keychain items the Slack MCP uses. No Slack app, therefore no Events API: the inbound
side polls (`$TEAMUP_SLACK_POLL`, default 10s — Tier-3, one poller per channel), asking
only for replies newer than the newest one it knows minus a 60s margin (`oldest=`), so a
busy thread costs a few KB per poll instead of the last 50 code blocks. Those tokens
rotate, and the failure mode is **silence**, indistinguishable from a quiet channel — so
the bridge auth-checks loudly at `on`, and once polls have failed for 5 minutes straight
posts a warning into the thread *and* says it on the channel (`.slack.broken`), then a
"back up" line when polling recovers. Shorter blips (laptop sleep, flaky wifi) stay
silent: each report wakes every agent on the channel. A reply is marked relayed only
after the channel accepted it, so a failed `say` is retried on the next poll.

Destination resolves `TEAMUP_SLACK_CHANNEL` → the id in `slack-channel` at the skill root
→ the user's self-DM. It is the private **#suss-teamup** channel (`C0BU8PNU5AQ`), which
also has **@Claude** in it, so the user can talk to a Slack-side Claude in a thread —
Slack refuses to add an agent to an existing DM ("agents can only be added at the start of
direct messages"), which is why a self-DM cannot serve. The bridge never creates a
channel: ad-hoc ones litter a shared workspace and archive rather than delete. One
channel, one thread per teamup channel, forever.
