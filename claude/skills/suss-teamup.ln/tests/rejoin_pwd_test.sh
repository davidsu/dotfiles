#!/usr/bin/env bash
# Rejoining a channel from another directory must replace the handle's registry row, not add
# one: `teams` prints a row per entry, so the statusline showed the channel once per directory.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TEAMUP="$TESTS_DIR/../scripts/teamup"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$(mktemp -d)"
export TEAMUP_SLACK=off
export TEAMUP_SESSION=sid-rejoin
trap 'rm -rf "$SUSS_TEAMUP_DIR" "$XDG_STATE_HOME"' EXIT

for dir in /tmp /usr /var; do
  "$TEAMUP" join rejoin_test --as rejoiner --pwd "$dir" --doing test --throwaway >/dev/null 2>&1
done

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

expect "one registry row per handle and channel" "$(wc -l < "$SUSS_TEAMUP_DIR/.sessions.tsv" | tr -d ' ')" "1"
expect "the row keeps the latest directory" "$(cut -f1 "$SUSS_TEAMUP_DIR/.sessions.tsv")" "/var"
expect "teams lists the channel once" "$("$TEAMUP" teams --session sid-rejoin)" "rejoin_test(1)"

exit "$fails"
