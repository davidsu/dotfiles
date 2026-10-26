open
# ⏪ Make self-rewind a skill, or a resource of one

## Summary

Turn [rewind_yourself.md](rewind_yourself.md) into something any agent can run: a script that takes the target prompt (by text, not a count) and does the three rounds, plus a page saying when to use it. David: "I can see this will be very useful to me".

## 🧭 To decide

- Where it lives: a resource of `suss-teamup` (it ties to sleep/wake: rewind, then sleep, so a wake resumes clean) or of `suss-troubleshoot-david-away` (it is a screen action), or its own skill.
- Pick the entry by its text: read the screenshot (or the session transcript's prompt list) to count `Up` presses, instead of a hard-coded count.

## ✅ Done when

- One command rewinds the calling agent to a named prompt, gated as in the memo, with screenshots kept.
- Proven on a throwaway agent, not on a working one.

---
**Created by**: actors.owner.2 (2026-10-26), at David's ask
**b44sync**: never
