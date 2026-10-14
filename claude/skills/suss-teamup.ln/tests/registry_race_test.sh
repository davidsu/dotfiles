#!/usr/bin/env bash
# Concurrent leaves must not lose parked or registry rows: every rewrite of .sessions.tsv and
# parked.tsv is read-modify-write, so without a lock two leaves can collapse the file to one row.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TEAMUP="$TESTS_DIR/../scripts/teamup"
readonly HANDLES=20
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$(mktemp -d)"
export TEAMUP_SLACK=off
trap 'rm -rf "$SUSS_TEAMUP_DIR" "$XDG_STATE_HOME"' EXIT

handle() { printf 'racer.%02d' "$1"; }

for n in $(seq 1 "$HANDLES"); do
  TEAMUP_SESSION="sid-$n" "$TEAMUP" join race_test --as "$(handle "$n")" --pwd /tmp --doing test --throwaway >/dev/null 2>&1
done
joined="$(wc -l < "$SUSS_TEAMUP_DIR/.sessions.tsv" | tr -d ' ')"

for n in $(seq 1 "$HANDLES"); do
  "$TEAMUP" leave race_test --as "$(handle "$n")" >/dev/null 2>&1 &
done
wait

fails=0
expect() { [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }; }

expect "every join registered a row" "$joined" "$HANDLES"
expect "every concurrent leave parked its handle" "$(wc -l < "$XDG_STATE_HOME/suss-teamup/parked.tsv" | tr -d ' ')" "$HANDLES"
expect "no parked row is missing its session id" "$(awk -F'\t' '$2==""' "$XDG_STATE_HOME/suss-teamup/parked.tsv" | wc -l | tr -d ' ')" "0"
expect "the registry is empty after everyone left" "$(wc -l < "$SUSS_TEAMUP_DIR/.sessions.tsv" | tr -d ' ')" "0"
leftovers() { ls "$XDG_STATE_HOME/suss-teamup/" "$SUSS_TEAMUP_DIR" | rg -c --no-config 'parked\.tsv\.|sessions\.tsv\.' || echo 0; }
expect "no temp file or lock is left behind" "$(leftovers)" "0"

exit "$fails"
