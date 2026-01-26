#!/usr/bin/env bash
set -euo pipefail

REPO_HTTPS="https://github.com/davidsu/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if ! command -v brew >/dev/null 2>&1; then
  # Download then run with /dev/tty so user gets full TTY (progress + prompts work)
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/brew-install.sh
  bash /tmp/brew-install.sh < /dev/tty || fail "Homebrew install failed."
  rm -f /tmp/brew-install.sh

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

git clone "$REPO_HTTPS" "$DOTFILES_DIR" || fail "git clone failed."

# Install mise and Bun for TypeScript installation scripts
if ! command -v mise >/dev/null 2>&1; then
  brew install mise || fail "mise install failed."
fi

mise use --global bun@latest || fail "bun install failed."
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Run TypeScript installation script
bun "$DOTFILES_DIR/installation/install.ts" || fail "install.ts failed."

# Switch to SSH remote for future git operations
cd "$DOTFILES_DIR"
git remote set-url origin git@github.com:davidsu/dotfiles.git

echo ""
echo "==================================================================="
echo "Installation complete!"
echo ""
echo "Your dotfiles repo is now configured to use SSH."
echo "To push/pull changes, you need to set up an SSH key:"
echo ""
echo "  1. Generate an SSH key (if you don't have one):"
echo "     ssh-keygen -t ed25519 -C \"thistooshallpass@only.constant.is.change.com\""
echo ""
echo "  2. Add the key to your SSH agent:"
echo "     ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
echo ""
echo "  3. Copy your public key and add it to GitHub:"
echo "     pbcopy < ~/.ssh/id_ed25519.pub"
echo "     # Then go to: https://github.com/settings/keys"
echo ""
echo "  Or run steps 1-3 in a single command:"
echo "     ssh-keygen -t ed25519 -C \"thistooshallpass@only.constant.is.change.com\" -f ~/.ssh/id_ed25519 -N \"\" && ssh-add --apple-use-keychain ~/.ssh/id_ed25519 && pbcopy < ~/.ssh/id_ed25519.pub"
echo ""
echo "  4. Test the connection:"
echo "     ssh -T git@github.com"
echo "==================================================================="


