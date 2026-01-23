#!/usr/bin/env bash

# Verification Script for Dotfiles
# Post-install validation using brew bundle check

# Source logging if not already available
if [[ -z "$(declare -F log_info)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

verify_all_tools() {
    local brewfile="$(dirname "${BASH_SOURCE[0]}")/Brewfile"

    log_info "Verifying all packages are installed..."

    if brew bundle check --file="$brewfile" >/dev/null 2>&1; then
        log_success "All packages verified."
    else
        log_error "Some packages are missing:"
        brew bundle check --file="$brewfile"
        return 1
    fi
}
