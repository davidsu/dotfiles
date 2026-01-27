#!/usr/bin/env bash
set -euo pipefail

REPO_HTTPS="https://github.com/davidsu/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || fail "Homebrew install failed."

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    fail "brew not found after install."
  fi
fi

if ! command -v git >/dev/null 2>&1; then
  brew install git < /dev/null || fail "git install failed."
fi

if [[ -e "$DOTFILES_DIR" ]]; then
  fail "$DOTFILES_DIR already exists."
fi

# Run git clone and bun install in parallel
git clone "$REPO_HTTPS" "$DOTFILES_DIR" &
clone_pid=$!

if ! command -v bun >/dev/null 2>&1; then
  brew tap oven-sh/bun
  brew install bun < /dev/null &
  bun_pid=$!
else
  bun_pid=""
fi

wait "$clone_pid" || fail "git clone failed."
[[ -n "$bun_pid" ]] && { wait "$bun_pid" || fail "bun install failed."; }

# Run TypeScript installation script
bun "$DOTFILES_DIR/installation/install.ts" || fail "install.ts failed."

# Switch to SSH remote for future git operations
cd "$DOTFILES_DIR"
git remote set-url origin git@github.com:davidsu/dotfiles.git


