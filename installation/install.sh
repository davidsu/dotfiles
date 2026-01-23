#!/usr/bin/env bash

# Main Installation Script (Bootstrap)
# This script orchestrates the installation process.

set -e # Exit on error

# Get the directory where this script is located
INST_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

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

    # 3. Symlinking
    node "${INST_DIR}/links.js"

    # 4. Verification
    verify_all_tools

    # 5. Post-installation steps
    post_install

    log_success "Installation and verification completed successfully."
    log_banner "MANUAL STEPS REQUIRED - See README.md → 'Post-install manual steps'"
}

# Post-installation configurations (tool-specific)
post_install() {
    log_info "Running post-installation configurations..."

    # Trust mise config if it exists
    local mise_config="${HOME}/.dotfiles/DOTconfig.home.symlink/mise/config.toml"
    if [[ -f "$mise_config" ]] && command -v mise >/dev/null 2>&1; then
        log_info "Trusting mise configuration..."
        mise trust "$mise_config"
    fi

    # Apply macOS defaults
    log_info "Applying macOS defaults..."
    bash "${INST_DIR}/macos-defaults.sh"
}

# Run main function
main "$@"

