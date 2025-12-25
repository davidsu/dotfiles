#!/usr/bin/env bash

# Main Installation Script (Bootstrap)
# This script orchestrates the installation process.

set -e # Exit on error

# Get the directory where this script is located
INST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper scripts from the same directory
source "${INST_DIR}/logging.sh"
source "${INST_DIR}/system.sh"
source "${INST_DIR}/dependencies.sh"
source "${INST_DIR}/verify.sh"

main() {
    log_info "Starting dotfiles installation from ${INST_DIR}..."

    # 1. Pre-flight Checks
    log_info "Running pre-flight checks..."

    if ! is_macos; then
        log_error "This dotfiles configuration is macOS-only. Exiting."
        exit 1
    fi

    log_success "macOS detected (v$(get_macos_version))"
    log_info "Logs will be written to ~/Library/Logs/dotfiles/"

    # 2. Dependency Resolution
    resolve_dependencies

    # 3. Verification
    verify_all_tools

    log_success "Installation and verification completed successfully."
}

# Run main function
main "$@"

