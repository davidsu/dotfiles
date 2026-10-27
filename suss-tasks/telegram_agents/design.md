# 📨 How the Telegram design got here

Session transcript: `~/.claude/projects/-Users-thistooshallpass--dotfiles/aa5e2534-db71-4198-a17b-8fd21560b950.jsonl` (line numbers below).

1. **2026-10-26, latency.** The bridge relayed whole teamup channels to one bot chat, and answered
   slower than the WhatsApp bridge. Split into threads (`2077519`).
2. **Separate chats.** David wanted finances and lead.home apart: one bot each (`754945b`). Then a
   group per bot, so more bots can join later (line 794: "one group just me and homie … one just
   me and finances … if I need more bots to join the channel they may").
3. **2026-10-27, two bots in one group.** David put Finances into the homie group; replies and
   readability fixes followed (`907d0d1`, WhatsApp-style `agent: handle` signature).
4. **Restated design** (lines 2391–2441), after a misunderstanding relayed through lead.home:
   - Groups are David's personal concerns: Home and Finances now, more later. Don't rigidify.
   - No two agents share a bot. Owners keep theirs (lead.home → homie, finances → finances); others
     take one from a pool of 15 and return it when they leave. A pool bot's name says nothing, so
     its agent signs every message.
   - Inbound: a Telegram @mention of a bot reaches its agent, a reply reaches the bubble's agent,
     anything else reaches every agent in the group. No parsing names out of the text.
   - "Join X to us" just gets done by whoever is addressed; not spelled out.
   - This Mac mirrors no teamup channel anywhere; agents post to David on purpose.
   - Docs short, for tomorrow's agents (line 2418: "don't write for yesterday's agent").
5. **Secrets** (line 2493: "I hate secrets on files"): bot tokens move to the keychain.
6. **After first use** (2026-10-27 04:50, via lead.home on tg-latency): David wants the Slack habit
   after all. A message starting with an agent's name goes to that agent (handle, bot name or
   @username, since Telegram's @-autocomplete gives the username, not the name). Every agent signs.
   And "pls ack asap, the silence is annoying": a rule for every agent.
7. **Adding a bot to a group** (2026-10-27): the Bot API can't. Options were a Telegram client
   logged in as David, taps on his phone over adb, or his Brave Telegram Web tab. David picked the
   first: `suss-telegram-user` (Telethon, own venv) holds his session in the keychain and claim
   adds the bot in under 2 s. Release takes the bot out of the group, owners' bots included.
