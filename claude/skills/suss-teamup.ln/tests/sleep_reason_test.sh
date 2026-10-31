#!/usr/bin/env bash
# Every sleep says why and what wakes it (David 2026-10-31): teamup-sleep refuses without both, keeps them for
# teamup-wake --list, and notes them on each channel the agent leaves.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)" XDG_STATE_HOME="$(mktemp -d)"
trap 'rm -rf "$SUSS_TEAMUP_DIR" "$XDG_STATE_HOME"' EXIT

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

"$TESTS_DIR/../scripts/teamup-sleep" --force owner.x >/dev/null 2>&1
expect "a sleep without --why/--wakes-on is refused" "$?" "2"
expect "the refusal shows the protocol" \
  "$("$TESTS_DIR/../scripts/teamup-sleep" --why 'done' owner.x 2>&1 | sed -n '2p' | cut -c1-49)" \
  "Every sleep says why and what wakes it (David 202"

source "$TESTS_DIR/../scripts/teamup-sleep"
mkdir -p "$SUSS_TEAMUP_DIR/reason_test/members" && touch "$SUSS_TEAMUP_DIR/reason_test/members/owner.x"
state_sleep_reason owner.x "au1 blocked" "David picks a/b/c"
expect "the reason is kept for teamup-wake --list" \
  "$(sed -n '1,2p' "$XDG_STATE_HOME/suss-teamup/sleeping/owner.x" | paste -sd'|' -)" "why=au1 blocked|wakes_on=David picks a/b/c"
expect "each channel it is on gets the reason as a note" \
  "$(tail -1 "$SUSS_TEAMUP_DIR/reason_test/channel.tsv" | cut -f2-4)" \
  "$(printf 'owner.x\tnote\t💤 sleeping: au1 blocked · wakes on: David picks a/b/c')"

exit "$fails"
