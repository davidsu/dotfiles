#!/usr/bin/env bash

# Logging Utilities for Dotfiles Installation
# Dual output to terminal and log files

LOG_DIR="${HOME}/Library/Logs/dotfiles"
INSTALL_LOG="${LOG_DIR}/install.log"
ERROR_LOG="${LOG_DIR}/install_errors.log"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local formatted_msg="[${timestamp}] [${level}] ${message}"

    # Write to install log
    echo "${formatted_msg}" >> "${INSTALL_LOG}"

    # Print to terminal with color
    echo -e "${color}${formatted_msg}${NC}"
}

log_info() {
    _log "INFO" "${BLUE}" "$1"
}

log_success() {
    _log "SUCCESS" "${GREEN}" "$1"
}

log_warn() {
    _log "WARN" "${YELLOW}" "$1"
}

log_error() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local formatted_msg="[${timestamp}] [ERROR] ${message}"

    # Write to both logs
    echo "${formatted_msg}" >> "${INSTALL_LOG}"
    echo "${formatted_msg}" >> "${ERROR_LOG}"

    # Print to stderr with color
    echo -e "${RED}${formatted_msg}${NC}" >&2
}

log_banner() {
    local message="$1"
    local width=60
    local border=$(printf '=%.0s' $(seq 1 $width))

    echo ""
    echo -e "${YELLOW}${border}${NC}"
    echo -e "${YELLOW}  $message${NC}"
    echo -e "${YELLOW}${border}${NC}"
    echo ""

    # Also log to file
    echo "" >> "${INSTALL_LOG}"
    echo "$border" >> "${INSTALL_LOG}"
    echo "  $message" >> "${INSTALL_LOG}"
    echo "$border" >> "${INSTALL_LOG}"
}

