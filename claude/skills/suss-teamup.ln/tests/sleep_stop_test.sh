#!/usr/bin/env bash
# teamup-sleep stops the agent's claude by pid before closing its tab: the pid comes from the
# registry's session id via ~/.claude/sessions/{pid}.json, and a SIGHUP must end it.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export HOME="$(mktemp -d)"
trap 'rm -rf "$SUSS_TEAMUP_DIR" "$HOME"; kill "$fake_claude" 2>/dev/null' EXIT

source "$TESTS_DIR/../scripts/teamup-sleep"

bash -c 'trap "exit 0" HUP; while :; do sleep 1; done' &
fake_claude=$!
mkdir -p "$HOME/.claude/sessions"
printf '{"sessionId":"sid-1","name":"owner.x"}' > "$HOME/.claude/sessions/$fake_claude.json"
printf '/tmp\tguard_test\towner.x\tsid-1\n' > "$REGISTRY"

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

expect "the handle maps to its claude pid" "$(claude_pid_of owner.x)" "$fake_claude"
expect "an unregistered handle has no pid" "$(claude_pid_of nobody)" ""
hang_up_claude "$fake_claude"; expect "a hang-up ends the process" "$?" "0"
sleep 0.2
kill -0 "$fake_claude" 2>/dev/null; expect "the process is gone afterwards" "$?" "1"

exit "$fails"
