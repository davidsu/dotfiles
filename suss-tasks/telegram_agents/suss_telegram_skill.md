in_progress
# 📨 Skill suss-telegram: agents post to David on purpose

## Summary

Replace channel relaying with a skill of its own: an agent claims a bot (its own or one from the
pool), says what it has for David, gets his messages (mention, reply, or broadcast to the group),
and releases a pool bot when it leaves. This Mac mirrors no teamup channel; the per-machine mirror
setting belongs to teamup.slacktoggle's work. Design: [design.md](design.md), item 4.

Built: `~/.dotfiles/claude/skills/suss-telegram.ln/` (`claim`, `say`, `release`, `status`, `setup`);
`teamup-telegram` and its channel relay are gone. Every bot is polled by one daemon, which gathers
the copies of one David message for 3 s to spot a reply (a name or mention is read from each copy alone), because a bot never sees
another bot's message and so can't tell that David replied to it. `teamup leave --all` releases the
agent's bot. Left: David's checks from his phone (mention, reply, broadcast).

---
**Created by**: teamup.telegram (2026-10-27)
**b44sync**: never
