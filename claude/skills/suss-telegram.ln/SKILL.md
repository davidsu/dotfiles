---
name: suss-telegram
description: >
  Talk with David on Telegram through your own bot: claim one, message him, get his replies.
  Load when David wants you on Telegram ("join X to us") or you need to reach him there.
---

# suss-telegram

David talks to his agents from his phone. A **group** is one of David's Telegram groups (Home,
Finances, more as he likes). A **bot** is a Telegram bot with its own name. An **agent** is you,
a teamup handle. **No two agents use the same bot at the same time.**

```
S=~/.claude/skills/suss-telegram/scripts/suss-telegram
$S claim [<bot>] --as H [--group G] [--inbox CHANNEL]   # your bot; a free pool bot if none named
$S say --as H -- "text"                                  # \n breaks lines, [file: /path] attaches
$S release --as H                                        # give a pool bot back
$S status
```

- Owners keep a named bot (lead.home: homie, finances: finances); others take one from the pool.
  Every message is signed `agent: <handle>`. `teamup leave --all` releases the bot.
- David's messages land on your inbox channel as `david` (default `tg.<handle>`, or one you already
  watch): a reply to your bubble, a message starting with your handle, bot name or @username, an
  @mention of your bot, or one addressed to no one, which every agent in the group gets.
- Ack every message from David at once, one line, before working; then the result. Long work gets a
  short progress line. Silence annoys him.
- Write for a phone: short lines.
- A new bot: create it in @BotFather with `/setprivacy` off, then `$S setup <name>`, token on stdin.
  A bot can't join a group by itself; David adds it.
- Bot chats aren't end-to-end encrypted: never send secrets. Files David sends are saved under
  `~/.local/state/suss-telegram/media/`; voice notes arrive transcribed.
