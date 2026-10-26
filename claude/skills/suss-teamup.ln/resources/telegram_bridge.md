# The Telegram bridge

`scripts/teamup-telegram` relays teamup channels to David's Telegram through his own bots. Each bot
lives in its own group with David (group `finances` ← bot Finances, group `homie` ← bot homie), so
more bots can join a group later. Each relayed channel is bound to one bot.

```
scripts/teamup-telegram setup <bot>               # new bot: token on stdin; then David sends /start in its group
scripts/teamup-telegram on <subject> --bot <bot>  # relay a channel on that bot (starts the daemon)
scripts/teamup-telegram off <subject>             # stop it (the last one stops the daemon)
scripts/teamup-telegram status                    # daemon pid, last relay, bots, channel → bot
```

- **New bot**: create it in @BotFather, `/setprivacy` → Disable (so it reads every group message, not
  only commands), make a group with David and the bot, run `setup <bot>` (stop the daemon first: two
  getUpdates on one bot conflict), and send `/start` in the group. Its profile photo can be set with
  the Bot API's `setMyProfilePhoto`.

- **Out**: agent lines tagged `[top]` or naming `@david`, as `<subject> · <handle>: text`. No backfill.
- **Line breaks**: teamup lines are single-line, so write a literal `\n` (backslash, n) where the phone
  should break the line; the leading `@david ` is dropped. Short lines and bullets read far better on a phone.
- **Copy-paste text**: `@david [copy] <text>` goes out as the text alone, with no `subject · handle` line, so
  David can copy the whole bubble (a reply to a bank, a message for someone). Send the explanation separately.
- **Files out**: each `[file: /absolute/path]` in a relayed line is sent as a document after the
  text (a missing or failed file is reported in the chat instead).
- **In**: a Telegram reply to a relayed message lands on its subject as `re #<seq> …` (wakes its
  author); any other message lands on the bot's channel that spoke last. 👍 = posted, 👎 = refused.
- **Attachments in**: photos, voice notes, audio, video and documents are saved to
  `~/.local/state/suss-teamup/telegram/media/` and posted as `[<kind>: <path>]` next to the caption.
  Voice, audio and round videos are transcribed locally (whisper-cli + ffmpeg, model
  `~/.local/share/whisper/ggml-medium.bin`) and posted as `transcript: …`.
- Posts as `david`, which teamup exempts from the read-before-post check, so it never fights
  `teamup-slack` for a cursor. It tails `channel.tsv` with its own cursor and never joins, so it
  is not a peer in anyone's wake rules.
- Survives reboots: every `teamup join` runs `teamup-telegram auto`, which restarts the daemon if
  any channel is relayed. A recreated channel (shorter `channel.tsv`) restarts its cursor at 0.
- Latency: three threads, so no direction waits on another. Out stat-polls each `channel.tsv` every
  0.3 s; in long-polls Telegram (10 s, retried at once after a stalled read); deliveries (downloads,
  transcription, posting) run in order on the third.
- Only David (`david_id`, his user id) in the bot's own group is accepted; anything else is logged and dropped.
- Secrets: `~/.local/share/suss-teamup/telegram.json` (`david_id`, and `bots.<name>.token` / `.chat_id`), 0600. Not `~/.config`: here it is a symlink into this public repo.
- State and log: `~/.local/state/suss-teamup/telegram/` (`daemon.log`).
- Privacy: bot chats are Telegram cloud chats, encrypted to Telegram's servers, not end-to-end
  ([FAQ](https://telegram.org/faq)). Fine for pings and status, not for secrets.
