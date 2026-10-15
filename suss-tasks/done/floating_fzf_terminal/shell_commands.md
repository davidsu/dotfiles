closed
# 🔎 Shell commands open the same picker inline: alive-agents, available-agents, terminal-tabs

## Summary

David (2026-10-15 08:11, #suss-lead, via lead.24): "Want to invoke with terminal cmd, eg alive-agents". Zsh aliases run
`iterm_agent_picker --pick <list>` in the current tab (fzf in place, like `mru` / `jfzf`), no floating window.

David (08:16): "Alias to bot-available and bot-awake" → the names are `bot-awake` (alive agents), `bot-available` (awake + asleep),
`terminal-tabs`; the long `alive-agents` / `available-agents` names were dropped (one name per command). Aliases in
`zsh/sources/aliases.zsh`.

## Notes

- Done in dotfiles master 15e985b (local, not pushed). Video (bot-awake inline): `/private/tmp/claude-501/-Users-davidsu--dotfiles/4ca290d2-b989-4d0a-ab79-70bff3ea1262/scratchpad/bot_awake.mp4`.
