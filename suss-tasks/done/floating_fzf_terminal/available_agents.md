closed
# 🔎 available-agents: awake + parked agents, Enter wakes a parked one and focuses its tab

## Summary

David (2026-10-15 08:11): "I need a available-agents with list of all agents that can be woke up or are awake. On select wake
up and focus". Parked agents come from `teamup-wake --list` (`~/.local/state/suss-teamup/parked.tsv`), shown dim; Enter runs
`teamup-wake <handle>` then focuses the new tab. Preview: awake → live colored screen; parked → cwd, channels, slept-since, tail
of the transcript's last assistant message.

## Notes

- Done in dotfiles master 15e985b (local). The asleep set equals `teamup-wake --list` exactly (49 agents, same rules: not running, transcript exists). Video: `/private/tmp/claude-501/-Users-davidsu--dotfiles/4ca290d2-b989-4d0a-ab79-70bff3ea1262/scratchpad/bot_available.mp4` (no agent woken in the demo).
