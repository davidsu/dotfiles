#!/bin/bash
SP="$1"; UP="${2:-7}"; G=$HOME/.claude/skills/suss-troubleshoot-david-away/scripts/gate
sleep 15
name=$(osascript -e 'tell application "iTerm2" to name of current session of current window' 2>/dev/null)
echo "front session: $name"
[[ "$name" == *"actors.owner.2 (claude)"* ]] || { echo "ABORT: my tab is not the current session"; exit 1; }
$G key iTerm2 -- 'key code 53' || exit 1; sleep 0.3
$G key iTerm2 -- 'key code 53' || exit 1; sleep 1.5
for i in $(seq 1 "$UP"); do $G key iTerm2 -- 'key code 126' || exit 1; sleep 0.3; done
sleep 1
$G key iTerm2 -- 'key code 36' || exit 1; sleep 1.5
screencapture -x "$SP/rewind_final_confirm.png"
$G key iTerm2 -- 'key code 36' || exit 1; sleep 3
screencapture -x "$SP/rewind_final_after.png"
echo done
