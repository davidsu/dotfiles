#!/usr/bin/env bash
# teamup-sleep's "David messaged it lately" guard against a throwaway channel: his own lines count, bridge-relayed agent lines do not.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
readonly CHANNEL_DIR="$SUSS_TEAMUP_DIR/guard_test"
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

source "$TESTS_DIR/../scripts/teamup-sleep"

mkdir -p "$CHANNEL_DIR"
fails=0
expect_last_dm() { # label tsv-lines expected
  printf '%b' "$2" > "$CHANNEL_DIR/channel.tsv"
  local got; got="$(last_slack_dm_at owner.x)"
  [ "$got" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$got], expected [$3]"; fails=1; }
}

expect_last_dm "David naming the agent counts" \
  '2026-10-13T09:00:00Z\tdavid\tsay\t@owner.x please look\n' "2026-10-13T09:00:00Z"
expect_last_dm "a bridge-relayed agent say does not count" \
  '2026-10-13T09:00:00Z\tdavid\tsay\t[other.agent] @owner.x please look\n' ""
expect_last_dm "a bridge-relayed agent ask does not count" \
  '2026-10-13T09:00:00Z\tdavid\task\t@owner.x [other.agent] please look\n' ""
expect_last_dm "the newest of David's own lines wins over a relayed one" \
  '2026-10-13T09:00:00Z\tdavid\tsay\t@owner.x first\n2026-10-13T09:05:00Z\tdavid\tsay\t[other.agent] @owner.x relayed\n' "2026-10-13T09:00:00Z"
expect_last_dm "David quoting brackets mid-sentence still counts" \
  '2026-10-13T09:00:00Z\tdavid\tsay\t@owner.x see [this] note\n' "2026-10-13T09:00:00Z"
expect_last_dm "David's top-level Slack message (tagged [top] by the bridge) counts" \
  '2026-10-13T09:00:00Z\tdavid\tsay\t@owner.x please look [top]\n' "2026-10-13T09:00:00Z"

exit "$fails"
