# Story: iTerm2 crashed twice on a profile value (2026-10-14)

Source: `suss-tasks/dotfiles/floating_fzf_terminal/epic.md` (Notes 00:13, 06:49; Lessons).

## What happened

- The fzf agent picker's dynamic profile set `"Window Type": 19`, copied from iTerm2's master header.
  Installed iTerm2 was 3.7.3, whose enum ends at 18.
- 00:13: `create window with profile "Agent Picker"` crashed iTerm2. The agent saw AppleScript
  `Connection is invalid (-609)`, took it for a transient error, and went on. The GUI was down 00:13–00:16.
- 06:49: the same call, on the lead's GO for a demo video, crashed it again: SIGABRT, assertion in
  `iTermThemedWindowType` ← `-[iTermController windowTypeForBookmark:percentage:]` ← `iTermNewWindowCommand`
  (`~/Library/Logs/DiagnosticReports/iTerm2-2026-10-14-064934.ips`). The per-key gate aborted, no key was sent.
- Every shell survived both times on `iTermServer-3.7.3`.

## How it was solved

- `Window Type` 12 (`WINDOW_TYPE_NO_TITLE_BAR`, present in 3.7.3) and centering by the script (5d8b1fc, then 89a49dc on master).
- iTerm2 relaunched; the agents' tabs came back without their colors and with stale titles until each agent redrew.
- David, 06:50, on being asked to relaunch: "quit and reopen. Why am I needed???".

## What could be done differently

- Validate the key against `?ref=v3.7.3` before installing the profile.
- Treat `-609` as "the app died under my call": `ls -t ~/Library/Logs/DiagnosticReports | head` at 00:13 would have shown the crash and saved the 06:49 repeat.
- Relaunch iTerm2 at once and say so; restore tab colors with `iterm_tab_style`.
