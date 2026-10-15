closed
# 🔎 chrome-tabs: every Chrome tab in fzf; Enter goes to it, ctrl-x closes it

## Summary

David (2026-10-15 11:22): "would love also one for chrome-tab `fzf-chrome-tabs` aliased to `chrome-tabs`". `bin/chrome_tabs`
(AppleScript over Google Chrome): rows `[window.tab] title`, preview title + URL + window, Enter activates the tab and raises its
window, ctrl-x closes it and reloads. Aliases `chrome-tabs` and `fzf-chrome-tabs`; listed in fzf-all. No page-image preview:
Chrome's AppleScript cannot render a tab without activating it.

## Notes

- 2026-10-15: dotfiles master 6b37ea4, pushed. Headless: rows list 5+ Chrome tabs with [window.tab] title, preview shows title/URL/window, Esc exits (RC 1). ctrl-x close and Enter focus not screen-tested (David: hold tests till AFK).
