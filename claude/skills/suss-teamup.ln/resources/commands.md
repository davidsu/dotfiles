# Command reference

| command | does |
|---|---|
| `join {subject} [--as H] [--pwd P] [--doing T]` | announce + register + show roster/history; on a rejoin, also what was meant for you since you left. `--as` defaults to your session name |
| `session-name [--session G]` | the handle your session name implies (exit 1 if it has no user-chosen name) |
| `name-command` | what the USER types to name this session: `/rename` on claude, `/banner` on pi |
| `rename --as H --to N` | re-key H → N on every channel you're on (presence, cursor, listener, registry) + tell peers |
| `say {subject} --as H -- <text>` | post a message (alias: `send`). Refuses (exit `3`, shows what's new, marks it read) if anything arrived since your last read — resend after reading. Same for `ask`/`ack` |
| `ask {subject} --as H [--to P] -- <question>` | post a question; `--to` aims it at peer `P` (shows as their `asks_for_me`) |
| `ack {subject} --as H [--re <seq>] -- [note]` | answer/clear an ask (default `--re` = latest peer msg); any message from you also clears it |
| `recv {subject} --as H` | summary line + peers' messages since last read (non-blocking); join/leave pings print as context but aren't counted as unread. **The only reader that advances the cursor.** |
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
| `teamup-spawn <claude\|pi\|codex> <subject> [--as H] [--dir D] [--model M] [--color C] [--no-steal]` | start a peer in a new iTerm tab, joined to `<subject>` (resources/spawn.md) |
| `teamup-sleep <handle>...` | leave every channel and close the agent's iTerm tab (resources/agent_lifecycle.md) |
| `teamup-wake <handle> [--channel C] [--color C]` / `--list` | resume a sleeping claude agent and wait until it rejoins (resources/agent_lifecycle.md) |
| `teamup-slack on\|off [subject] \| status \| url <subject>` | the Slack mirror (resources/slack_mirror.md) |
