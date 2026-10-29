closed
# 📬 Joins, pre-spawn briefs, bridge notices and the stop hook stop waking bystanders

## Summary

David saw agent A wake for every exchange between the lead and agent B. Four holes:

1. A join `ping` woke every listener. Now it wakes only whoever `@`-named the joiner before it came (the lead that briefed it), or the one agent it joins as company.
2. An `@name` counted only if that handle had already written on the channel, so a brief posted before spawning its peer read as unaddressed and woke the bystander. Now any `@name` from an agent counts; from the human only a known handle (author or member) does, so a stray `@word` still wakes everyone.
3. The Slack bridge posted its housekeeping (thread URL, bridge down/up) as the human, unaddressed, waking everyone. It now posts a `note`, which `recv` shows and no wait fires on.
4. The stop hook held an agent on any unread. It now holds only on unread that would have woken it (`status` prints `for_me=`).

## Details

- Wake rules: `meant_for` in `claude/skills/suss-teamup.ln/scripts/teamup`
- Stop hook: `claude/skills/suss-teamup.ln/scripts/teamup-hook` reads `for_me=` from `teamup status`
- Tests: `tests/wake_rules_test.sh`, `tests/stop_hook_test.sh`

---
**Created by**: wake.noise.owner (2026-10-29), at David's ask
**b44sync**: never
