#!/usr/bin/env bash
# teamup-spawn --no-steal skips only the typed `/color`: the iTerm tab color is an escape sequence
# written to the tab's tty, focus-free, so the peer still gets it. Stubbed terminal, no keystrokes.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export SUSS_TEAMUP_DIR="$SANDBOX/teamup" HOME="$SANDBOX/home"
unset CLAUDE_CODE_SESSION_ID ITERM_SESSION_ID TEAMUP_AFTER_HANDLE

readonly SPAWN="$TESTS_DIR/../scripts/teamup-spawn"
readonly PAINTED="$SANDBOX/painted.log" TYPED="$SANDBOX/typed.log"
readonly STUBS="$SANDBOX/bin"
mkdir -p "$STUBS" "$HOME/.dotfiles/bin"
stub() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1"; chmod +x "$1"; } # path body
stub "$STUBS/term_spawn" '[ "$1" = --resolve ] && echo iterm || echo FAKE-SESSION'
stub "$STUBS/osascript" "echo \"\$*\" >> '$TYPED'"
stub "$HOME/.dotfiles/bin/iterm_tab_style" "echo \"\$*\" >> '$PAINTED'"
export PATH="$STUBS:$PATH"

fails=0
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }
}
spawn_and_read_paint() { # spawn args...
  rm -f "$PAINTED" "$TYPED"
  "$SPAWN" "$@" >/dev/null 2>&1
  cat "$PAINTED" 2>/dev/null
}

expect_text "claude --no-steal --color paints the tab" \
  "$(spawn_and_read_paint claude subj --as peer.a --color green --no-steal)" "--session FAKE-SESSION --color green"
expect_text "claude --no-steal types nothing into the tab" "$(cat "$TYPED" 2>/dev/null)" ""
expect_text "claude --no-steal --role lead paints the role color" \
  "$(spawn_and_read_paint claude subj --as peer.b --role lead --no-steal)" "--session FAKE-SESSION --color blue"
expect_text "--no-color is the same flag" \
  "$(spawn_and_read_paint claude subj --as peer.c --color purple --no-color)" "--session FAKE-SESSION --color purple"
expect_text "codex --no-steal still paints the tab" \
  "$(spawn_and_read_paint codex subj --as peer.d --color red --no-steal)" "--session FAKE-SESSION --color red"

exit "$fails"
