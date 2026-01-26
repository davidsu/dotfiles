#!/usr/bin/env bash

# Dependency Management for Dotfiles
# Handles Homebrew installation and brew bundle
#
# NOTE: This script is designed for macOS with Apple Silicon (M1/M2/M3/M4)

# Source logging if not already available
if [[ -z "$(declare -F log_info)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Function to install Homebrew if missing
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Apple Silicon Homebrew path
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log_success "Homebrew is already installed."
    fi
}

# Bootstrap mise, bun, and node (needed for links.ts and general dev work)
bootstrap_js_runtime() {
    log_info "Bootstrapping mise, Bun, and Node.js..."

    if ! command -v mise >/dev/null 2>&1; then
        log_info "Installing mise via Homebrew..."
        brew install mise
    fi

    # Activate mise in the current shell
    eval "$(/opt/homebrew/bin/mise activate bash)"

    if ! command -v bun >/dev/null 2>&1; then
        log_info "Installing Bun via mise..."
        mise use --global bun@latest
        eval "$(/opt/homebrew/bin/mise activate bash)"
    fi

    if ! command -v node >/dev/null 2>&1; then
        log_info "Installing Node.js via mise..."
        mise use --global node@lts
        eval "$(/opt/homebrew/bin/mise activate bash)"
    fi

    log_success "JS runtimes (Bun and Node.js) are ready."
}

# Install all tools via brew bundle
install_tools() {
    local brewfile="$(dirname "${BASH_SOURCE[0]}")/Brewfile"

    log_info "Installing packages via brew bundle..."
    brew bundle --file="$brewfile"
    log_success "All packages installed."
}

# Main dependency resolution logic
resolve_dependencies() {
    log_info "Starting dependency resolution..."

    install_homebrew
    bootstrap_js_runtime
    install_tools

    log_success "Dependency resolution completed."
}
