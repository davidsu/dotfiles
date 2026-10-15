#!/usr/bin/env bash
# `recv > /dev/null` must not mark lines read nobody saw: a lead lost a peer's message that way
# (suss-lead #314, 2026-10-15), then posted as if up to date. And a refused post must say so loudly.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export TEAMUP_SLACK=off
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly CLI="$TESTS_DIR/../scripts/teamup"
readonly SUBJECT=discard_test

fails=0
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }
}

"$CLI" join "$SUBJECT" --as reader --pwd /t --doing test >/dev/null
"$CLI" join "$SUBJECT" --as writer --pwd /t --doing test >/dev/null
"$CLI" recv "$SUBJECT" --as reader >/dev/null 2>&1
"$CLI" recv "$SUBJECT" --as reader | cat >/dev/null
"$CLI" say "$SUBJECT" --as writer -- "the message nobody may lose" >/dev/null

warning="$("$CLI" recv "$SUBJECT" --as reader 2>&1 >/dev/null)"; status=$?
expect_text "recv to /dev/null exits 3" "$status" "3"
expect_text "recv to /dev/null says on stderr that nothing was read" "$(head -1 <<<"$warning")" \
  "✗ NOT READ (exit 3): recv's output went to /dev/null, so the cursor stays put. Run recv again and read what it prints."

refusal="$("$CLI" say "$SUBJECT" --as reader -- "posted from a stale view")"; status=$?
expect_text "the next say is refused, the lost message still unread" "$status" "3"
expect_text "the refusal leads with a loud line" "$(head -1 <<<"$refusal")" \
  "✗ NOT POSTED (exit 3): the channel changed since you last read it. Read this, then send again if it still makes sense:"
expect_text "the refusal shows the lost message" "$(grep -c 'the message nobody may lose' <<<"$refusal")" "1"

expect_text "a recv piped elsewhere still reads" "$("$CLI" recv "$SUBJECT" --as reader | head -1)" \
  "summary: unread=0 asks_for_me=0 from=none"

"$CLI" say "$SUBJECT" --as writer -- "noise a watcher never reads" >/dev/null
"$CLI" recv "$SUBJECT" --as reader --discard >/dev/null; status=$?
expect_text "recv --discard into /dev/null succeeds" "$status" "0"
expect_text "recv --discard marks everything read" "$("$CLI" say "$SUBJECT" --as reader -- "fresh view")" "sent."

exit "$fails"
