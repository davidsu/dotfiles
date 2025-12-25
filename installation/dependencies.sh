#!/usr/bin/env bash

# Dependency Management for Dotfiles
# Handles Homebrew and tool installation driven by tools.json

# Source logging if not already available
if [[ -z "$(declare -F log_info)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Function to install Homebrew if missing
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        log_success "Homebrew is already installed."
    fi
}

# Function to bootstrap mise and node so we can use JS for parsing
bootstrap_js_runtime() {
    log_info "Bootstrapping mise and Node.js..."
    
    if ! command -v mise >/dev/null 2>&1; then
        log_info "Installing mise via Homebrew..."
        brew install mise
    fi

    # Activate mise in the current shell
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/mise activate bash)"
    else
        eval "$(/usr/local/bin/mise activate bash)"
    fi

    if ! command -v node >/dev/null 2>&1; then
        log_info "Installing Node.js via mise..."
        mise use --global node@lts
    fi
    
    log_success "JS runtime (Node.js) is ready."
}

# Function to install tools from tools.json
install_tools() {
    local tools_json
    tools_json="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.json"
    
    log_info "Parsing tools from tools.json using Node.js..."
    
    # Use Node.js to extract the list of brew packages
    local packages
    packages=$(node -e "
        const fs = require('fs');
        const { tools } = JSON.parse(fs.readFileSync('$tools_json', 'utf8'));
        const packages = Object.keys(tools).map(name => tools[name].homebrew_package || name);
        console.log(packages.join(' '));
    ")

    log_info "Installing packages: $packages"
    
    for pkg in $packages; do
        if brew list "$pkg" >/dev/null 2>&1; then
            log_success "$pkg is already installed."
        else
            log_info "Installing $pkg..."
            brew install "$pkg"
        fi
    done
}

# Main dependency resolution logic
resolve_dependencies() {
    log_info "Starting dependency resolution..."
    
    install_homebrew
    bootstrap_js_runtime
    install_tools
    
    log_success "Dependency resolution completed."
}
