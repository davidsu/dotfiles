# The Telegram bridge

`scripts/teamup-telegram` relays teamup channels to David's chat with his own Telegram bot.

```
scripts/teamup-telegram setup            # once: waits for David's /start, records his chat id
scripts/teamup-telegram on <subject>     # relay a channel (starts the daemon)
scripts/teamup-telegram off <subject>    # stop it (the last one stops the daemon)
scripts/teamup-telegram status           # daemon pid, last relay, relayed channels
```

- **Out**: agent lines tagged `[top]` or naming `@david`, as `<subject> · <handle>: text`. No backfill.
- **In**: a Telegram reply to a relayed message lands on its subject as `re #<seq> …` (wakes its
  author); any other message lands on the subject that spoke last. 👍 = posted, 👎 = refused.
- Posts as `david`, which teamup exempts from the read-before-post check, so it never fights
  `teamup-slack` for a cursor. It tails `channel.tsv` with its own cursor and never joins, so it
  is not a peer in anyone's wake rules.
- Only David's chat id is accepted; anything else is logged and dropped.
- Secrets: `~/.local/share/suss-teamup/telegram.json` (`token`, `chat_id`), 0600. Not `~/.config`: here it is a symlink into this public repo.
- State and log: `~/.local/state/suss-teamup/telegram/` (`daemon.log`).
- Privacy: bot chats are Telegram cloud chats, encrypted to Telegram's servers, not end-to-end
  ([FAQ](https://telegram.org/faq)). Fine for pings and status, not for secrets.
