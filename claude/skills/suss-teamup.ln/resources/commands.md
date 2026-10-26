# Command reference

| command | does |
|---|---|
| `join {subject} [--as H] [--pwd P] [--doing T] [--gist G] [--throwaway] [--no-slack]` | announce + register + show roster/history; `--gist` (first one wins) heads the Slack thread, else the opener's `--doing`; `--throwaway` marks an agents-only channel (mirrored to #suss-throwaway); `--no-slack` opts the channel out of the Slack mirror for good (`.slack.off` in the channel dir, so later joins and `teamup-slack auto|on` skip it too); on a rejoin, also what was meant for you since you left. Marks read only what precedes your join, so a message landing mid-join stays unread (flagged at the end) and your first `wait` fires on it. `--as` defaults to your session name |
| `session-name [--session G]` | the handle your session name implies (exit 1 if it has no user-chosen name) |
| `name-command` | what the USER types to name this session: `/rename` on claude, `/banner` on pi |
| `rename --as H --to N` | re-key H → N on every channel you're on (presence, cursor, listener, registry) + tell peers |
| `say {subject} --as H -- <text>` | post a message (alias: `send`). Refuses (exit `3`, shows what's new, marks it read) if anything arrived since your last read — resend after reading. Same for `ask`/`ack` |
| `ask {subject} --as H [--to P] -- <question>` | post a question; `--to` aims it at peer `P` (shows as their `asks_for_me`); queued if `P` is asleep, refused if `P` is unknown |
| `ack {subject} --as H [--re <seq>] -- [note]` | answer/clear an ask (default `--re` = latest peer msg); any message from you also clears it |
| `say\|ask\|ack {subject} --as H --top -- …` | the Slack mirror posts this line at the channel's **top level** instead of the thread (body suffix ` [top]`); only where the channel owns its Slack channel (`slack-channel.{subject}` or `--throwaway`), exit `2` elsewhere. A message from the user tagged ` [top]` came from the top level: answer it with `--top` (resources/slack_mirror.md) |
| `recv {subject} --as H` | summary line + peers' messages since last read (non-blocking); join/leave pings print as context but aren't counted as unread. **The only reader that advances the cursor.** Into `/dev/null` it reads nothing: exit `3`, cursor untouched, so the next `say` shows you what you would have missed. `--discard` marks everything read unseen, for scripts that post but never read (the watchers) |
| `status {subject} --as H` | summary line only (incl. `listener=live\|none`); cursor untouched; exit `0`=clean `1`=unread `2`=ask-for-you |
| `status --as H` | no subject: list every team this handle is on + member count |
| `teams --session G [--pwd P]` | compact one-line joined channels for a statusline (`!` ask, `*` unread); empty when on none |
| `wait {subject} --as H [--timeout S]` | block until a peer says something meant for you (resources/listening.md: from the human, `@you`/`@all`, a reply to you, a join, or anything when you are the only other agent) that you have not read, or timeout (`--timeout 0` = forever, for background idle waits; a second one stands by instead of exiting). Exits `0` only with something to read, `1` on timeout/left-channel, and names the case on its last `wake:` line. A second expiry with nothing new on the channel says `STOP LOOPING` + how to go idle on your harness. **Signal-only: does NOT consume — `recv` after waking.** Not on pi for idle waiting (resources/listening.md). |
| `roster {subject}` | who's on the channel |
| `peek {subject} [--last N]` | recent history (default 20) |
| `leave {subject} --as H` / `leave --all --as H` | disconnect |
| `erase {subject} [--force]` (alias `cleanup`) | delete the channel + its registry rows; refuses if members remain unless `--force` |
| `channels` | list active subjects |

Every message has a stable `#seq` id (its line number); `recv`/`peek`/`wait`
print it so you can `ack --re <seq>` a specific message.

State lives under `$SUSS_TEAMUP_DIR` (default `/tmp/suss-teamup`). Cleared on
reboot; that's fine — channels are ephemeral per work session.

Separate scripts in `scripts/`:

| script | does |
|---|---|
| `teamup-spawn <claude\|pi\|codex> <subject> [--as H] [--dir D] [--model M] [--role R] [--color C] [--after H]` | start a peer in a new iTerm tab right of yours (or of `--after`'s), joined to `<subject>` (resources/spawn.md) |
| `teamup-sleep [<handle\|session-id>...]` | leave every channel and close the agent's iTerm tab; no argument: your own session (resources/agent_lifecycle.md) |
| `teamup-wake <handle> [--channel C] [--role R] [--color C] [--after H]` / `--list` | resume a sleeping claude agent and wait until it rejoins (resources/agent_lifecycle.md) |
| `teamup-focus on [--skip H] \| off \| status` | while the user is away (no input for 2 min), never leave the screen >3 min without a claude iTerm tab in front (checks every minute): a busy one, else the most recently active live session's; `on` is idempotent and race-safe, `off` stops every poller, log in `~/.local/state/suss-teamup/focus.log` (resources/tracking_agents.md) |
| `teamup-focus-test` | black-box test of the running poller, only while the user is away: Finder in front, PASS if a claude tab returns within 75 s; FAILs with the poller off |
| `teamup-focus-stress lifecycle\|focus [--skip H]` | lifecycle: hammer concurrent `on`/`off` (bridges, stale pid, kill -9, stale lock), asserting one poller or none, touches no window; focus: opens fake agent windows, so only when nobody is even watching the screen (idle ≥ 120 s cannot tell) |
| `teamup-slack on\|off [subject] \| status \| url <subject>` | the Slack mirror (resources/slack_mirror.md) |
| `teamup-slack-watch on <name> <subject> <handle> <query> [skip-regex] \| off <name> \| status` | Slack search hits → a teamup channel (resources/slack_mirror.md) |
| `teamup-telegram setup <bot> \| on <subject> --bot <bot> \| off <subject> \| status` | a channel's [top] and @david lines → its bot's Telegram group with David, his replies back as `david` (resources/telegram_bridge.md) |
| `teamup-mac-notify-watch on <name> <subject> <handle> <app-bundle-id> <title> \| off <name> \| status` | macOS notifications from one app with one title → a teamup channel (resources/slack_mirror.md) |
