#!/usr/bin/env bash

# System Utilities for Dotfiles Installation

# Enforce macOS only
is_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 1
    fi
    return 0
}

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure a directory exists and log it
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_info "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Check macOS version
get_macos_version() {
    sw_vers -productVersion
}

