in_progress
# 📨 A pool of 15 bots

## Summary

David asked for 15 spare bots with plain-word names he can tag (line 2391 of the session in
[design.md](design.md): "something human that I can easily tag … not bot1 bot2"). Created from his
Telegram Web through @BotFather, privacy mode off, names amber … otter.

After 4 bots BotFather answered "too many attempts. Please try again in 56839 seconds"
(2026-10-27 06:15, so until 22:03). The rest create themselves: `suss-telegram-user fill-pool`
(Telethon, as David, talking to @BotFather) runs from the LaunchAgent
`~/Library/LaunchAgents/com.susskind.suss-telegram-fill-pool.plist` at :05 every hour, never
before the wait BotFather named (`~/.local/state/suss-telegram/botfather_next_try`), and removes
itself once the pool holds 15. Log: `~/.local/state/suss-telegram/fill_pool.log`.

| Bot   | Username                 | Taken by   |
|-------|--------------------------|------------|
| amber | susskind_amber_9ud1_bot  | aws.photos |
| birch | susskind_birch_6duu_bot  |            |
| cedar | susskind_cedar_f32g_bot  |            |
| dune  | susskind_dune_b98u_bot   |            |

---
**Created by**: teamup.telegram (2026-10-27)
**b44sync**: never
