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

# Run git clone and mise install in parallel
git clone "$REPO_HTTPS" "$DOTFILES_DIR" &
clone_pid=$!

if ! command -v mise >/dev/null 2>&1; then
  brew install mise < /dev/null &
  mise_pid=$!
else
  mise_pid=""
fi

wait "$clone_pid" || fail "git clone failed."
[[ -n "$mise_pid" ]] && { wait "$mise_pid" || fail "mise install failed."; }

mise use --global bun@latest || fail "bun install failed."
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Run TypeScript installation script
bun "$DOTFILES_DIR/installation/install.ts" || fail "install.ts failed."

# Switch to SSH remote for future git operations
cd "$DOTFILES_DIR"
git remote set-url origin git@github.com:davidsu/dotfiles.git


