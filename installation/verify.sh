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
    
    # Use Node.js to extract tool name and its command name
    # Format: tool_name:cmd_name
    local tools_to_check
    tools_to_check=$(node -e "
        const fs = require('fs');
        const { tools } = JSON.parse(fs.readFileSync('$tools_json', 'utf8'));
        Object.keys(tools).forEach(name => {
            const cmd = tools[name].cmd || name;
            console.log(\`\${name}:\${cmd}\`);
        });
    ")

    for entry in $tools_to_check; do
        local tool_name="${entry%%:*}"
        local cmd_name="${entry#*:}"
        
        if has_command "$cmd_name"; then
            log_success "Verified: $tool_name (as $cmd_name)"
        else
            log_error "Missing: $tool_name (expected command '$cmd_name' not in PATH)"
            failed=$((failed + 1))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tools from tools.json verified successfully."
    else
        log_error "Verification failed for $failed tool(s)."
        return 1
    fi
}
