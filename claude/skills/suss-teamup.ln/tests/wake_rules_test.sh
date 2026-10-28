#!/usr/bin/env bash
# Who a line wakes: a join wakes only whoever named the joiner, a brief to a peer not yet here
# stays addressed, the human's stray @word still wakes everyone, a bridge note wakes no one.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export TEAMUP_SLACK=off
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly CLI="$TESTS_DIR/../scripts/teamup"
readonly CHANNEL=wake_test

fails=0
expect() { # label command...
  local label="$1"; shift
  "$@" && echo "ok   $label" || { echo "FAIL $label"; fails=1; }
}

join() { "$CLI" join "$CHANNEL" --as "$1" --pwd /t --doing test >/dev/null; }
catch_up() { "$CLI" recv "$CHANNEL" --as "$1" >/dev/null 2>&1 || "$CLI" recv "$CHANNEL" --as "$1" --discard >/dev/null; }
say_as() { catch_up "$1"; "$CLI" say "$CHANNEL" --as "$1" -- "$2" >/dev/null; }
is_woken() { "$CLI" wait "$CHANNEL" --as "$1" --timeout 1 >/dev/null 2>&1; }
is_not_woken() { ! is_woken "$1"; }
settle() { for handle in "$@"; do catch_up "$handle"; done; }

join david
join lead
join owner.a
expect "the first peer's join wakes the agent alone on the channel" is_woken lead
settle lead owner.a

say_as lead "@owner.b brief: take the parser"
expect "a brief to a peer not yet here does not wake the bystander" is_not_woken owner.a

join owner.b
expect "the join wakes the lead that named the joiner" is_woken lead
expect "the join does not wake a bystander" is_not_woken owner.a
settle lead owner.a owner.b

"$CLI" say "$CHANNEL" --as david -- "ping davidsu@example.com about @types/node" >/dev/null
expect "the human's line naming no known handle wakes every agent" is_woken owner.a
settle lead owner.a owner.b

"$CLI" say "$CHANNEL" --as david -- "@owner.b please check" >/dev/null
expect "the human's line to a known handle does not wake a bystander" is_not_woken owner.a
settle lead owner.a owner.b

say_as lead "@all stand-up in 5"
expect "@all still wakes everyone" is_woken owner.a
settle lead owner.a owner.b

"$CLI" note "$CHANNEL" --as david -- "bridge is down" >/dev/null
expect "a bridge note wakes no one" is_not_woken owner.a
expect "a bridge note is still read by recv" bash -c "'$CLI' recv '$CHANNEL' --as owner.a | grep -q 'bridge is down'"

exit $fails
