#!/usr/bin/env bash
# `join --no-slack`: the channel is marked once, later joins leave the mark, and the bridge refuses to mirror it.
# No Slack, no keychain: the bridge exits before any connector call.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export XDG_CONFIG_HOME="$SUSS_TEAMUP_DIR/config"
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly CLI="$TESTS_DIR/../scripts/teamup"
readonly BRIDGE="$TESTS_DIR/../scripts/teamup-slack"
readonly OPTED_OUT=quiet_test
readonly MARKER="$SUSS_TEAMUP_DIR/$OPTED_OUT/.slack.off"

fails=0
expect() { # label command...
  local label="$1"; shift
  "$@" && echo "ok   $label" || { echo "FAIL $label"; fails=1; }
}

TEAMUP_SLACK=off "$CLI" join "$OPTED_OUT" --as first --pwd /t --doing test --no-slack >/dev/null
expect "join --no-slack marks the channel" test -f "$MARKER"
TEAMUP_SLACK=off "$CLI" join "$OPTED_OUT" --as second --pwd /t --doing test >/dev/null
expect "a later join without the flag keeps the mark" test -f "$MARKER"
expect "teamup-slack on skips the channel" bash -c "'$BRIDGE' on '$OPTED_OUT' | grep -q 'opted out'"
expect "teamup-slack auto skips the channel" bash -c "'$BRIDGE' auto '$OPTED_OUT'; test ! -f '$SUSS_TEAMUP_DIR/$OPTED_OUT/.slack.on'"

TEAMUP_SLACK=off "$CLI" join plain_test --as first --pwd /t --doing test >/dev/null
expect "a normal channel is not marked" test ! -f "$SUSS_TEAMUP_DIR/plain_test/.slack.off"

readonly MACHINE_CONFIG="$XDG_CONFIG_HOME/suss-teamup/local.conf"
mkdir -p "$(dirname "$MACHINE_CONFIG")"
echo 'slack=off' > "$MACHINE_CONFIG"
"$CLI" join machine_off_test --as first --pwd /t --doing test >/dev/null
expect "slack=off in local.conf: teamup-slack on refuses" bash -c "'$BRIDGE' on machine_off_test | grep -q 'off on this machine'"
expect "slack=off in local.conf: teamup-slack auto mirrors nothing" bash -c "'$BRIDGE' auto machine_off_test; test ! -f '$SUSS_TEAMUP_DIR/machine_off_test/.slack.on'"

exit $fails
