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

git clone "$REPO_HTTPS" "$DOTFILES_DIR" || fail "git clone failed."

# Install mise and Bun for TypeScript installation scripts
if ! command -v mise >/dev/null 2>&1; then
  brew install mise < /dev/null || fail "mise install failed."
fi

mise use --global bun@latest || fail "bun install failed."
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Run TypeScript installation script
bun "$DOTFILES_DIR/installation/install.ts" || fail "install.ts failed."

# Switch to SSH remote for future git operations
cd "$DOTFILES_DIR"
git remote set-url origin git@github.com:davidsu/dotfiles.git

echo ""
echo "============================================================"
echo "  Bootstrap complete!"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  1. Set up SSH key for GitHub (see README.md → Git/GitHub section)"
echo "  2. Complete other manual steps (see README.md → Post-install manual steps)"
echo ""
echo "View README: cat ~/.dotfiles/README.md | less"
echo "============================================================"


