#!/bin/bash
SP="$1"; G=$HOME/.claude/skills/suss-troubleshoot-david-away/scripts/gate
sleep 15
name=$(osascript -e 'tell application "iTerm2" to name of current session of current window' 2>/dev/null)
echo "front session: $name"
[[ "$name" == *"actors.owner.2 (claude)"* ]] || { echo "ABORT: my tab is not the current session"; exit 1; }
$G key iTerm2 -- 'key code 53' || exit 1; sleep 0.3
$G key iTerm2 -- 'key code 53' || exit 1; sleep 1.5
for i in 1 2 3 4 5 6; do $G key iTerm2 -- 'key code 126' || exit 1; sleep 0.3; done
sleep 1
screencapture -x "$SP/rewind_up6.png"
$G key iTerm2 -- 'key code 53'; sleep 0.5
$G key iTerm2 -- 'key code 53'; sleep 1
screencapture -x "$SP/rewind_closed.png"
echo done
