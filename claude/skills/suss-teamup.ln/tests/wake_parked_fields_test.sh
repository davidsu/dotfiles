#!/usr/bin/env bash
# A parked.tsv row with an empty channels field (an agent that slept on no channel) keeps it empty: a tab is IFS
# whitespace, so `read` collapsed the run of tabs and woke home.claude.2 onto a channel named after its timestamp.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)" XDG_STATE_HOME="$(mktemp -d)"
trap 'rm -rf "$SUSS_TEAMUP_DIR" "$XDG_STATE_HOME"' EXIT

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

source "$TESTS_DIR/../scripts/teamup-wake"
spawned="$XDG_STATE_HOME/spawned"
term_spawn() { printf '%s\n' "$*" > "$spawned"; echo tab-1; }
wait_for_join_ping() { return 0; }
is_claude_session() { return 0; }
is_session_running() { return 1; }
wake_color() { :; }

mkdir -p "$(dirname "$PARKED")"
printf 'owner.x\tsid-x\t/tmp\t\t2026-10-31T02:10:28Z\n' > "$PARKED"
printf 'owner.y\tsid-y\t/tmp\tchan_a,chan_b\t2026-10-31T02:10:28Z\n' >> "$PARKED"

expect "a sleeper on no channel is woken on no channel" \
  "$(wake owner.x "" "" "" "" 2>&1 | tail -1)" "owner.x is back (it was on no channel)."
expect "its resume command joins nothing" "$(sed -n 's/.*--run \(.*\) --background/\1/p' "$spawned")" "cyc --resume sid-x"
expect "a sleeper on channels rejoins the first one" \
  "$(wake owner.y "" "" "" "" 2>&1 | tail -1)" "owner.y is back on 'chan_a'."
expect "--asleep finds the session id of a channel-less sleeper" "$(can_wake owner.x && echo yes)" "yes"

exit "$fails"
