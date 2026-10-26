#!/bin/bash
SP="$1"; G=$HOME/.claude/skills/suss-troubleshoot-david-away/scripts/gate
sleep 15
name=$(osascript -e 'tell application "iTerm2" to name of current session of current window' 2>/dev/null)
echo "front session: $name"
[[ "$name" == *"actors.owner.2 (claude)"* ]] || { echo "ABORT: my tab is not the current session"; exit 1; }
$G key iTerm2 -- 'key code 53' || { echo "ABORT: iTerm2 not frontmost"; exit 1; }
sleep 0.3
$G key iTerm2 -- 'key code 53' || exit 1
sleep 1.5
screencapture -x "$SP/rewind_menu.png"
$G key iTerm2 -- 'key code 53'
sleep 1
screencapture -x "$SP/rewind_after_esc.png"
echo done
