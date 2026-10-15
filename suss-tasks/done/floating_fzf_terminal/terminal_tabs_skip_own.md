closed
# 🔎 terminal-tabs: leave out the tab the picker itself runs in

## Summary

David (2026-10-15 11:11, in lead.25's terminal): "lets remove the current tab from the list. this is incredibly helpful and well
done. thank owner for me!" His screenshot: `terminal-tabs` opened from a bash tab listed that very tab first, previewing itself.
Fix in `bin/iterm_picker_lists`: `tab_rows` drops the row whose tty is the picker's own (`tty`), so neither the inline picker's
shell tab nor the floating picker window appears. Matched by tty, not by name.

## Notes

- 2026-10-15 11:2x: dotfiles master 87e525a, pushed. Headless proof: `iterm_picker_lists rows tabs` lists 14 tabs with no tty on stdin, 13 with the picker's own tty on stdin and that tty's row gone. First attempt missed because the `tty` lookup ran inside the awk half of a pipeline (stdin = the pipe); it now runs before the pipeline.
- 2026-10-15 12:03, David via lead.25: an empty row "[w]" previewing "(not in an iTerm tab)" → the listing's trailing newline became a row; fixed in a35ece4 (rows need fields). Proof: 13 iTerm sessions, 13 rows, 12 with the own tty excluded, 0 empty rows.
- 2026-10-15 12:06, David via lead.25: "dont list agent tabs in this screen" → terminal-tabs skips every tab whose tty runs a claude, codex or pi process (`ps -A -o tty=,comm=`), agents stay in bot-awake / bot-available. 21eb16e, pushed. Proof: 13 rows before, 2 after (bash, caffeinate), 1 with the picker's own tty excluded; the 11 skipped ttys equal the 11 alive agents.
