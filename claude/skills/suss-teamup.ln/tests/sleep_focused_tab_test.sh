#!/usr/bin/env bash
# teamup-sleep never closes the tab David is typing in, --force and self-sleep included:
# fzf.terminal slept itself with --force while David typed a request into its tab (2026-10-15).
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

source "$TESTS_DIR/../scripts/teamup-sleep"

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

focused_title="" idle_seconds=0
focused_tab_name() { printf '%s' "$focused_title"; }
seconds_since_input() { echo "$idle_seconds"; }
is_focused_with() { # title idle-seconds
  focused_title="$1" idle_seconds="$2"
  is_focused owner.x && echo focused || echo not
}
expect "a busy claude's spinner title still matches" "$(is_focused_with '◐ owner.x (claude)' 5)" focused
expect "an idle claude's title matches" "$(is_focused_with '✳ owner.x (claude)' 5)" focused
expect "another handle ending the same does not match" "$(is_focused_with '✳ my.owner.x (claude)' 5)" not
expect "David away from the keyboard is not focus" "$(is_focused_with '✳ owner.x (claude)' 300)" not

put_to_sleep() { echo "slept $1"; }
is_busy() { return 1; }
focused_title='✳ owner.x (claude)' idle_seconds=5
expect "--force does not close the tab David is in" "$(sleep_if_allowed owner.x true 2>/dev/null)" ""
expect "the refusal says why" "$(sleep_if_allowed owner.x true 2>&1 >/dev/null)" \
  "teamup-sleep: not closing owner.x: David is in its tab right now (focused, typed within 120 s). No flag overrides this."
sleep_if_allowed owner.x true >/dev/null 2>&1; expect "a refusal exits non-zero" "$?" "1"
idle_seconds=300
expect "once David is idle, --force sleeps it" "$(sleep_if_allowed owner.x true 2>/dev/null)" "slept owner.x"

exit "$fails"
