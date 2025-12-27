#!/usr/bin/env bash
set -euo pipefail

REPO_SSH="git@github.com:davidsu/dotfiles.git"
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
  brew install git || fail "git install failed."
fi

if [[ -e "$DOTFILES_DIR" ]]; then
  fail "$DOTFILES_DIR already exists."
fi

ssh_out="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -T git@github.com 2>&1 || true)"
if printf '%s' "$ssh_out" | grep -qi 'permission denied (publickey)'; then
  cat >&2 <<'EOF'
ERROR: GitHub SSH not configured.

Create a key, add it to GitHub, then re-run:
  ssh-keygen -t ed25519 -C "you@example.com"
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  pbcopy < ~/.ssh/id_ed25519.pub
EOF
  exit 1
fi

git clone "$REPO_SSH" "$DOTFILES_DIR" || fail "git clone failed."
bash "$DOTFILES_DIR/installation/install.sh" || fail "install.sh failed."


