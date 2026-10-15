closed
# 🔎 Picker polish (no ctrl-j/k hint, smooth preview scroll, own tab really gone) + cmd+ctrl+t/c/b floating windows

## Summary

David, 2026-10-15 11:17-11:22, in fzf.terminal's terminal with screenshots: "ctrl+j/k -> ctrl+n/p is already native, no need";
"ctrl+u/d -> great idea, need smooth scroll"; terminal-tabs still showed the current tab; "if there is a global key for this
(like our cmd+ctrl+g) add this info to the list"; "I want a cmd_ctrl_{char} mapping that opens in a floating window much like
the cmd_ctrl_g does … mru (cmd_ctrl_t sounds fair for mru)" plus Chrome history/bookmarks.

## Notes

- dotfiles master a3b09ef + the bind fix after it: header without ctrl-j/k; ctrl-u/d scroll the preview 4 lines; the own-tab
  exclusion failed in David's run because fzf's reloads run the row command with stdin = a pipe, so `tty` was empty; the picker
  now resolves its tty once and exports `PICKER_OWN_TTY` (proof: 0 own rows of 13 through the reload path).
- fzf-all rows and preview show the global hotkey (cmd+ctrl+g bot-awake, cmd+ctrl+t mru, cmd+ctrl+c chromehistory,
  cmd+ctrl+b chromebookmarks).
- New `bin/iterm_float CMD`: the floating window generalized (the agent picker uses it too). Karabiner: cmd+ctrl+t → mru,
  cmd+ctrl+c → chromehistory, cmd+ctrl+b → chromebookmarks. cmd+ctrl+h was not free: Hammerspoon maps cmd+ctrl+h/j/k/l to arrows.
- Not screen-tested: David said "hold with tests till I'm afk".
- f9c008f: the first push had a trailing `+` in the ctrl-u/d bind that made fzf refuse to start; fixed and verified in tmux (prompt up, 9 tab rows, ctrl-d/u keep it alive, Esc → RC 1).
