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
