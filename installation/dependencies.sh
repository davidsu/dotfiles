#!/usr/bin/env bash

# Dependency Management for Dotfiles
# Handles Homebrew and tool installation driven by tools.json
#
# NOTE: This script is designed for macOS with Apple Silicon (M1/M2/M3/M4)
# Intel Mac support has been removed for simplicity

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

# Function to bootstrap mise and node so we can use JS for parsing
bootstrap_js_runtime() {
    log_info "Bootstrapping mise and Node.js..."
    
    if ! command -v mise >/dev/null 2>&1; then
        log_info "Installing mise via Homebrew..."
        brew install mise
    fi

    # Activate mise in the current shell (Apple Silicon path)
    eval "$(/opt/homebrew/bin/mise activate bash)"

    if ! command -v node >/dev/null 2>&1; then
        log_info "Installing Node.js via mise..."
        mise use --global node@lts

        # Reactivate mise to make node available in current shell
        eval "$(/opt/homebrew/bin/mise activate bash)"
    fi

    log_success "JS runtime (Node.js) is ready."
}

# Function to install tools from tools.json
install_tools() {
    local tools_json="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.json"
    
    log_info "Parsing tools from tools.json using Node.js..."
    log_info "Tools JSON path: ${tools_json}"

    # Use shared tools parser to extract package list for installation
    local packages
    packages=$(node "$(dirname "${tools_json}")/tools-parser.js" "${tools_json}" packages)

    log_info "Installing packages from tools.json"

    # Install packages one by one (read line by line)
    echo "$packages" | while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi

        # Parse package name and brew type from "package:type" format
        IFS=':' read -r pkg brew_type <<< "$line"
        log_info "Processing package: '$pkg' (type: $brew_type)"

        # Check if package is already installed based on brew type
        local is_installed=false
        if [[ "$brew_type" == "cask" ]]; then
            if brew list --cask "$pkg" >/dev/null 2>&1; then
                is_installed=true
            fi
        else
            if brew list "$pkg" >/dev/null 2>&1; then
                is_installed=true
            fi
        fi

        if [[ "$is_installed" == true ]]; then
            log_success "$pkg ($brew_type) is already installed."
        else
            log_info "Installing $pkg ($brew_type)..."
            if [[ "$brew_type" == "cask" ]]; then
                if brew install --cask "$pkg" < /dev/null; then
                    log_success "Successfully installed $pkg ($brew_type)"
                else
                    log_error "Failed to install $pkg ($brew_type)"
                fi
            else
                if brew install "$pkg" < /dev/null; then
                    log_success "Successfully installed $pkg ($brew_type)"
                else
                    log_error "Failed to install $pkg ($brew_type)"
                fi
            fi
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
