#!/usr/bin/env bash
# The stop hook holds an agent only on unread that would have woken it: traffic between
# two other agents waits for its next checkpoint, a message to it must be read first.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export TEAMUP_SLACK=off
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly CLI="$TESTS_DIR/../scripts/teamup"
readonly HOOK="$TESTS_DIR/../scripts/teamup-hook"
readonly CHANNEL=hook_test

fails=0
expect() { # label command...
  local label="$1"; shift
  "$@" && echo "ok   $label" || { echo "FAIL $label"; fails=1; }
}

join() { "$CLI" join "$CHANNEL" --as "$1" --pwd "/work/$1" --doing test >/dev/null; }
catch_up() { "$CLI" recv "$CHANNEL" --as "$1" --discard >/dev/null; }
say_as() { catch_up "$1"; "$CLI" say "$CHANNEL" --as "$1" -- "$2" >/dev/null; }
stop_is_allowed() { printf '{"cwd":"/work/%s"}' "$1" | "$HOOK" stop >/dev/null 2>&1; }
stop_is_held() { ! stop_is_allowed "$1"; }

join lead
join owner.a
join owner.b
for handle in lead owner.a owner.b; do catch_up "$handle"; done

say_as lead "@owner.b take the parser"
expect "a message to another agent lets the bystander idle" stop_is_allowed owner.a
expect "a message to an agent holds that agent until it reads" stop_is_held owner.b
catch_up owner.b
expect "reading it lets that agent idle" stop_is_allowed owner.b

say_as lead "@all wrap up"
expect "@all holds every agent" stop_is_held owner.a

exit $fails
