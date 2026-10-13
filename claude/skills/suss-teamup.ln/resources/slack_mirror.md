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

**Slack search watcher** — `scripts/teamup-slack-watch on {name} {subject} {handle} {query} [skip-regex]` polls
`search.messages` every 60s (`$TEAMUP_WATCH_POLL`) under the same session and says each new
hit on `{subject}` as `@{handle} new in #channel from author: text — permalink`, so an agent
wakes on a file event instead of polling Slack. A bot post with no text shows its attachments' pretext and title, and a hit matching `skip-regex` is dropped. Its first poll only records the baseline, and
hits in every mirror channel (`slack-channel`, `slack-channel.*`) are skipped. Each watch joins under its own `{name}`, so several share one inbox, and it joins with
`TEAMUP_SLACK=off`, which keeps raw hits out of Slack. State, pid and log: `~/.local/state/suss-teamup/slack/watch/{name}.*`. Used by the `slack.digest` agent
(suss-tasks `dotfiles/slack_digest/epic.md`).
Its sibling `scripts/teamup-mac-notify-watch` does the same for macOS notifications. It reads
Notification Center's sqlite db every 5s and says each new notification from one app with one
exact title. That covers WhatsApp Web in Brave: the title is the group, the body `~ sender: text`.

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
  become a dangling ask. A reply opening with the word `lead` (any case, `@` and a trailing
  `:`/`,` optional) goes as an `ask` to each live `lead*` agent; with no such agent it reads as
  ordinary text. Aiming is **not privacy**: every message lands on the shared
  channel and all agents read it; it only decides whose idle is blocked.
- **attribution** — the bridge posts under one handle, so a thread reply from anyone but
  the channel owner is prefixed `[slack: {name}]` (from `bot_profile.name`/`username`,
  else `users.info`). Without it, @Claude's replies arrived on the channel as the user's.
- **focus** — a reply from the channel owner means the user is away from the Mac, so the
  bridge runs `teamup-focus on` (idempotent): from then on, while no one touches the
  keyboard or mouse, the screen stays on an agent at work (resources/tracking_agents.md).

**It cannot loop.** Outbound, `recv` never returns this handle's own lines (`$3!=me`,
`teamup:234`), so anything injected from Slack can't be posted back. Inbound, a reply that is
an agent code block is split into its messages and each is looked up in **this machine's**
`channel.tsv` by seq, clock, handle and type: a match is our own mirror post, dropped. That
check replaced trusting `.slack.posted` alone, which the poller could read before
`post_to_thread` had appended to it, so the bridge's own code block came back as a reply from
the user (a user-session token posts as the user, so bridge posts and phone replies share one
author). The bridge's own notices (`:warning:`, `:white_check_mark:`, the retire line) are
dropped the same way. A code block that matches nothing local was mirrored by **another
machine's** bridge into the same thread (the Coder box and the laptop share one thread per
channel name): it is delivered, attributed `[{handle}]`, only when it says `@all` or names a
live local handle; everything else from the other machine stays in Slack. Plain replies are
delivered as before. Two more rules make the shared thread work across machines: `open_thread`
first looks for a root younger than a day whose text starts with `*teamup · {subject}* ` among the
channel's last 200 top-level messages (`conversations.history`, `oldest=`) and adopts it instead of
posting a new one (older roots are reused channel names and dead threads), relaying
only replies newer than the adoption (the older ones belong to the machine that opened it) and
skipping the backfill; and outbound, a reply (`re:#N`, `re #N`, `ack #N`) to a line that arrived
from another machine (`[handle] …` under the bridge's name) gets `@handle` inserted after the
`re:#N`, so the other machine's bridge delivers it to its author without anyone typing the handle.
`tests/slack_inbound_test.sh` drives all of this against a throwaway channel with no Slack.

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

**A dedicated Slack channel** — a `slack-channel.{subject}` file at the skill root mirrors that
one teamup channel into its own Slack channel instead: its thread is never unfollowed, and what the
user types at the channel's top level is relayed like a thread reply (so it also turns `teamup-focus` on).
Today: teamup `suss-lead` → private **#suss-lead** (`C0C9NE59T24`), the leads' private line to
the user (`suss-workflows` recipe `lead_role.md`). Repointing a live channel: `off`, move its
`{subject}.*` thread state aside, `on`.

**Throwaway channels** — `join --throwaway` touches `.slack.throwaway` in the channel dir, and the
bridge then mirrors into private **#suss-throwaway** (`C0C8PB41Z37`, file `slack-channel.throwaway`)
instead: agents-only channels (tests, probes) stay out of the user's #suss-teamup. Their thread
state lives in the channel dir, not `~/.local/state`, so `erase` (or a reboot clearing `/tmp`)
removes it and a later channel of the same name, throwaway or not, opens a fresh thread.
