# The Slack mirror

The mirror is the only Slack posting teamup does. A message an agent writes *directly* to a
Slack channel or thread for people (PR nudges, review replies) is not channel traffic: it
follows the `suss-communication` skill. Channel messages themselves stay plain one-line text.

Every channel is mirrored into a **Slack thread automatically** — `join` starts the
bridge (SKILL.md → Join, `mirror_to_slack_unless_bridge`), so the user can pick a channel up on a
phone without anyone having armed anything first. One thread per channel name, reused
across restarts, reboots and `erase`: the thread state (`{subject}.thread`, `.posted`,
`.relayed`, `.engaged`, `.url`) lives in `~/.local/state/suss-teamup/slack/`, not in the
ephemeral channel dir — when it lived there, a recreated channel opened a fresh thread and
the user kept replying into the old, unpolled one. A channel's mirror retires itself once the
channel has had no real member for 2 minutes (a single empty poll used to kill it during
an agent's leave/re-join). Replies typed while no mirror runs are not lost: the next
mirror for that channel relays every reply it has not relayed yet. **Nothing to invoke**
— the manual controls exist only for overriding it:

```
scripts/teamup-slack status          # the daemon, and which channels are mirrored
scripts/teamup-slack off [subject]   # stop mirroring (bare: all channels, and the daemon)
scripts/teamup-slack on  [subject]   # re-start one you turned off
scripts/teamup-slack url <subject>   # the channel's Slack thread permalink
```

**Finding a channel's Slack thread** — never reconstruct a permalink from `.thread`:
the bridge announces it on the channel (`mirror thread in Slack: <url>`) the first time a
mirror opens, writes it to `~/.local/state/suss-teamup/slack/{subject}.url`, and
`scripts/teamup-slack url {subject}` prints it. The team URL is learned from the first post the
connector makes, so a channel that *adopted* an existing thread gets its announcement
on the daemon's next outbound tick after any post.

## Auth: the claude.ai Slack connector, no Slack tokens

Until 2026-10-14 the bridge used the user's Slack web session (`xoxc` + `d` cookie from the
keychain). Slack rotated it at 07:33 and every bridge on both machines died with `invalid_auth`,
silently (`suss-troubleshoot-david-away/resources/stories/slack_session_rotation_2026_10_14.md`).
David: "this 'got my tokens from my browser' isn't good enough", and no Slack app / API key
either. The bridge now drives the **claude.ai Slack connector** (`mcp__claude_ai_Slack__*`), which
authenticates through claude.ai and is present in every Claude Code session on the laptop
(`claude mcp list` → `claude.ai Slack … ✔ Connected`).

The connector is only reachable from a Claude session, so `scripts/slack_connector.sh` runs a
**headless relay**: one `claude -p --model haiku` per batch of tool calls, told to make exactly the
listed calls with the given arguments and nothing else. The tool results are taken from the
`stream-json` transcript (`tool_use` joined to `tool_result` by id), never from the model's prose, and
each result is matched back to its request by exact arguments — a call the relay skipped is simply
missing, which the caller treats as a failure. The connector answers in prose, not JSON;
`connector_messages_json` parses the `detailed` read format (`Message TS:` blocks, `From:` lines,
`Reactions:`/`Files:`/`Thread:` trailers, the `*Sent using* <@…|Claude>` footer dropped) back into
`{ts, user, username, text, thread_ts}` so the delivery code did not change.

Costs and latency, measured 2026-10-14 (laptop, haiku): a relay is **6–14 s wall and $0.007–0.009**
for 1–4 calls; **19 s and $0.012** for 17 calls (haiku makes them one per turn whatever the prompt
says). Each relay line is logged with its cost in `~/.local/state/suss-teamup/slack/bridge.log`
(`relay: N turns, M ms, $C`), so the real per-day number is `grep relay bridge.log | awk …`.

| inbound poll (`TEAMUP_SLACK_POLL`) | relays/day | at 15 channels (17 reads, $0.012) | at 3 channels ($0.008) |
|---|---|---|---|
| 30 s (default) | 2880 | ≈ $34/day | ≈ $23/day |
| 60 s | 1440 | ≈ $17/day | ≈ $12/day |
| 120 s | 720 | ≈ $9/day | ≈ $6/day |

Outbound relays come on top, one per batch of new lines (a few cents an hour on a busy channel).
Measured end to end on a throwaway channel: channel line → Slack **19 s**; Slack reply → channel
**45–56 s** (the poll interval plus a relay). The fast alternative — calling the connector from bash
through Claude Code's own OAuth token and an undocumented Anthropic proxy, 1 s per call — was
measured and **rejected** (lead.20, 2026-10-14): a harvested session credential driving an
unofficial endpoint is the class David had just refused. The transport is one function
(`connector_calls`), so it can be swapped if he ever allows it.

What the connector cannot do: unfollow a thread (`subscriptions.thread.remove`), so David now
follows every mirrored thread he "posted" in; delete a message; post without the
`*Sent using* <@…|Claude>` footer. Messages are sent as **markdown** (the connector converts to
mrkdwn): the thread root is written `**teamup · {subject}** — gist` and comes back as Slack's
`*teamup · {subject}* — gist`, which is what `find_existing_root` matches.

## One daemon, every channel

`teamup-slack on {subject}` marks the channel (`.slack.on` in its dir), joins it as the bridge
handle, opens or adopts its thread, posts the backfill, and starts **one daemon**
(`__daemon`, pid in `~/.local/state/suss-teamup/slack/bridge.pid`, log `bridge.log`) if none runs.
The daemon loops:

- **out**, every 5 s: `recv` each mirrored channel; every new line becomes one post (code block,
  thread or top level), queued in `bridge.queue`; the head of the queue is flushed as **one ordered
  relay** of at most `max-turns - 1` posts (7: the relay makes one call per turn and needs the last
  turn to answer), so a burst keeps its order in Slack and a bigger one spans several flushes.
  Batching a wake's messages into one code block was tried before and hid answers inside a wall of
  text on a phone. The returned `message_ts` goes to `.posted`, and **only then does the post leave
  the queue**: one the relay skipped or Slack refused stays at the head for the next flush
  (`post unconfirmed on …` in the log), and is dropped after 3 attempts (`post lost on …`, with the
  connector's error). Before 2026-10-14 the queue was emptied before the relay ran, and a relay
  that answered in one turn without calling the tool, or hit the turn cap on a burst, silently
  lost its posts (71 in one day; `tests/flush_posts_test.sh`).
- **in**, every `TEAMUP_SLACK_POLL` s (default 30): **one relay** reads every mirrored thread
  (`slack_read_thread`, `oldest=` newest known reply minus 60 s) and, for a channel that owns its
  Slack channel, its top level too (`slack_read_channel`); each channel's results are merged and
  handed to `deliver_unseen_replies` → `say`, or `ask --to {handle}` when the reply starts with a
  **live** handle (`@` optional, `.` and `-` interchangeable: `lead.7 do X` aims at `lead-7`; the user
  is often on a phone keyboard), so an aimed reply wakes one agent and trips its Stop hook
  (`asks_for_me=1`) instead of waking the roster. A name no member holds is delivered to everyone
  and answered in the thread with the live handles. A reply opening with the word `lead` goes as an
  `ask` to each live `lead*` agent. Aiming is **not privacy**: every message lands on the shared
  channel; it only decides whose idle is blocked.
- **retire**: a channel with no real member for 2 minutes gets the `_channel is empty_` notice, the
  bridge leaves it and drops its marker; the daemon keeps running (and makes no relay) with zero
  channels.

**A running daemon keeps the code it started with.** After editing `teamup-slack`,
`slack_connector.sh` or `slack_inbound.sh`: `teamup-slack off` (bare — stops the daemon and leaves
every channel) then `on` per channel, or just `on {subject}` for one (it restarts nothing if the
daemon is alive). Per-channel pollers from before the daemon (`teamup-slack __run {subject}`) are
killed by `on`/`off` of that channel.

- **attribution** — the bridge posts under one handle, so a thread reply from anyone but
  the channel owner is prefixed `[slack: {name}]` (from the `From:` line, else
  `slack_read_user_profile`). Without it, @Claude's replies arrived on the channel as the user's.
- **focus** — a reply from the channel owner means the user is away from the Mac, so the
  bridge runs `teamup-focus on` (idempotent): from then on, while no one touches the
  keyboard or mouse, the screen stays on an agent's terminal (resources/tracking_agents.md).

**It cannot loop.** Outbound, `recv` never returns this handle's own lines (`$3!=me`,
`teamup:234`), so anything injected from Slack can't be posted back. Inbound, a reply that is
an agent code block is split into its messages and each is looked up in **this machine's**
`channel.tsv` by seq, clock, handle and type: a match is our own mirror post, dropped. That
check replaced trusting `.posted` alone, which the poll could read before the flush had appended
to it (connector posts and phone replies share one author: David). The bridge's own notices
(`:warning:`, `:white_check_mark:`, the retire line) are dropped the same way, and so is any other agent
code block in the thread: only this bridge posts them now. The `:warning: no agent here is called …`
notice answers a reply a person typed (a typo in Slack), where retyping fixes it. One more rule keeps a
thread stable across bridge restarts: `open_thread` first looks for a root younger than a day whose text
starts with `*teamup · {subject}* ` among the channel's recent top-level messages (`slack_read_channel`,
`oldest=`) and adopts it instead of posting a new one (older roots are reused channel names and dead
threads), relaying only replies newer than the adoption and skipping the backfill.
`tests/slack_inbound_test.sh` and `tests/toplevel_posting_test.sh` drive all of this against a
throwaway channel with a faked relay (`connector_call` / `connector_calls` redefined): no Slack.

**Failure is loud.** The failure mode of a dead transport is silence, indistinguishable from a quiet
channel — so `on` dies at once when the connector does not answer (`load_connector_identity`), and
once a channel's reads have failed for 5 minutes straight the daemon posts a warning into its thread
*and* says it on the channel (`.slack.broken`), then a "back up" line when reads recover. Shorter
blips stay silent: each report wakes every agent on the channel. A reply is marked relayed only
after the channel accepted it, so a failed `say` is retried on the next poll. Outbound, a post
stays queued until Slack confirmed it (3 attempts, then `post lost on {subject}: …` with the
connector's error in `bridge.log`); the relay's own stderr lands in `bridge.log` too.

Destination resolves `TEAMUP_SLACK_CHANNEL` → `slack-channel.{subject}` → the id in `slack-channel`
at the skill root. It is the private **#suss-teamup** channel (`C0BU8PNU5AQ`), which
also has **@Claude** in it, so the user can talk to a Slack-side Claude in a thread. The bridge
never creates a channel: ad-hoc ones litter a shared workspace and archive rather than delete. One
channel, one thread per teamup channel, forever.

**A dedicated Slack channel** — a `slack-channel.{subject}` file at the skill root mirrors that
one teamup channel into its own Slack channel instead, and what the user types at the channel's top
level is relayed like a thread reply (so it also turns `teamup-focus` on).
Today: teamup `suss-lead` → private **#suss-lead** (`C0C9NE59T24`), the leads' private line to
the user (`suss-workflows` recipe `lead_role.md`). Repointing a live channel: `off {subject}`, move
its `{subject}.*` thread state aside, `on {subject}`.

**Thread or top level — the agent decides per message.** The user reads a dedicated channel at
its top level, so an answer buried in the mirror thread is missed. `teamup say|ask|ack … --top`
appends ` [top]` to the line, and the bridge posts that line at the channel's top level (no
`thread_ts`, same code block, so the loop guards above still drop it when it comes back);
everything else stays in the thread. The tag is a suffix because a leading `[x]` already means
"relayed from agent x" (`teamup-sleep`'s guard, the reply cross-back). `--top` is allowed only
where the teamup channel owns its Slack channel — a `slack-channel.{subject}` file or
`--throwaway` — and is refused (exit 2) elsewhere: a top-level post in the shared #suss-teamup
would be noise for every other channel. Inbound is symmetric: a message the user types at the
top level arrives with the ` [top]` suffix, a thread reply without, so an agent answers in kind.
Rule of thumb for a lead: answer a `[top]` message with `--top`; status for David goes `--top`;
routine chatter and agent-to-agent traffic stay in the thread. A throwaway channel also relays
#suss-throwaway's top level, so a live test can round-trip there.

**The thread root** is `*teamup · {subject}* — {gist}`, written once when the thread opens: the
channel's `join --gist` (the first one given wins, kept in `.gist` in the channel dir), else the
opening agent's `--doing`, cut at 240 characters.

**Throwaway channels** — `join --throwaway` touches `.slack.throwaway` in the channel dir, and the
bridge then mirrors into private **#suss-throwaway** (`C0C8PB41Z37`, file `slack-channel.throwaway`)
instead: agents-only channels (tests, probes) stay out of the user's #suss-teamup. Their thread
state lives in the channel dir, not `~/.local/state`, so `erase` (or a reboot clearing `/tmp`)
removes it and a later channel of the same name, throwaway or not, opens a fresh thread.

**Still on the old session path** (fallback only, dead whenever the session rotates):
`scripts/teamup-slack-watch` (Slack search → channel, used by `slack.digest`) and
`scripts/teamup-tasks-sync` (task-file uploads). Both source `slack_session.sh`; porting them means
`slack_search_public_and_private` and the two-step `slack_get_file_upload_url` /
`slack_complete_file_upload` through `connector_call`.
`TEAMUP_SLACK=off` disables auto-mirroring entirely.
