#!/usr/bin/env bash

# Verification Script for Dotfiles
# Post-install validation driven by tools.json

# Source logging if not already available
if [[ -z "$(declare -F log_info)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Source system helpers
if [[ -z "$(declare -F has_command)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/system.sh"
fi

verify_all_tools() {
    local tools_json
    tools_json="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.json"
    log_info "Starting post-installation verification from tools.json using Node.js..."
    
    local failed=0
    
    # Use shared tools parser to extract verification data
    local tools_to_check
    tools_to_check=$(node "$(dirname "${tools_json}")/tools-parser.js" "${tools_json}" verification)

    for entry in $tools_to_check; do
        # Parse tool_name:brew_type:cmd_name
        IFS=':' read -r tool_name brew_type cmd_name <<< "$entry"

        if [[ "$brew_type" == "cask" ]]; then
            # For casks, check if installed via Homebrew cask
            if brew list --cask "$tool_name" >/dev/null 2>&1; then
                log_success "Verified: $tool_name (cask installed)"
            else
                log_error "Missing: $tool_name (cask not installed via Homebrew)"
                failed=$((failed + 1))
            fi
        else
            # For formulae, check if command is in PATH
            if has_command "$cmd_name"; then
                log_success "Verified: $tool_name (as $cmd_name)"
            else
                log_error "Missing: $tool_name (expected command '$cmd_name' not in PATH)"
                failed=$((failed + 1))
            fi
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tools from tools.json verified successfully."
    else
        log_error "Verification failed for $failed tool(s)."
        return 1
    fi
}
