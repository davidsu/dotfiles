closed
# 🔎 terminal-tabs: every iTerm tab with a screen preview; Enter focuses, a key closes the tab and keeps the picker open

## Summary

David (2026-10-15 08:11): "I need a list of all terminal tabs. And a way to close tab without closing picker, like ctrl-o opens
browser for chromehistory. All with previews". Rows: tab name + window; preview: live colored screen; Enter focuses; close key
(proposed ctrl-x) closes the session via AppleScript and reloads the list.

## Notes

- Done in dotfiles master 15e985b (local). Close key = `ctrl-x` (AppleScript `close` of the session, never the picker's own tab); the list reloads. Video: `/private/tmp/claude-501/-Users-davidsu--dotfiles/4ca290d2-b989-4d0a-ab79-70bff3ea1262/scratchpad/terminal_tabs.mp4` (ctrl-x closed demo-tab-2, tabs 2→1 by AppleScript).
