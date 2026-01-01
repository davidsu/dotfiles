#!/usr/bin/env bash
# Test installation script using Tart VM
# This script creates a fresh macOS VM and tests the dotfiles installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VM_NAME="dotfiles-test"
MACOS_IMAGE="ghcr.io/cirruslabs/macos-sonoma-vanilla:latest"
VM_DISK_SIZE=50
VM_MEMORY=8

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if tart is installed, install if missing
if ! command -v tart &> /dev/null; then
    warn "Tart is not installed. Installing via Homebrew..."

    # Check if brew is installed
    if ! command -v brew &> /dev/null; then
        error "Homebrew is not installed. Install from https://brew.sh"
    fi

    log "Running: brew install cirruslabs/cli/tart"
    brew install cirruslabs/cli/tart

    if ! command -v tart &> /dev/null; then
        error "Failed to install tart"
    fi

    log "Tart installed successfully"
fi

# Check if VM already exists
if tart list | grep -q "^$VM_NAME"; then
    warn "VM '$VM_NAME' already exists"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Deleting existing VM..."
        tart delete "$VM_NAME"
    else
        error "Aborted. Delete the VM manually with: tart delete $VM_NAME"
    fi
fi

# Clone the base image
log "Cloning macOS image (this may take a while on first run)..."
tart clone "$MACOS_IMAGE" "$VM_NAME"

# Configure VM settings
log "Configuring VM (disk: ${VM_DISK_SIZE}GB, memory: ${VM_MEMORY}GB)..."
tart set "$VM_NAME" --disk-size "$VM_DISK_SIZE" --memory "$((VM_MEMORY * 1024))"

BOOTSTRAP_URL="https://raw.githubusercontent.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/master/installation/bootstrap.sh"

log "VM created successfully: $VM_NAME"
log ""
log "Next steps:"
log ""
log "1. Start the VM:"
log "   tart run $VM_NAME"
log ""
log "2. Wait for macOS to boot (first boot takes 2-3 minutes)"
log "   A macOS window will open"
log ""
log "3. In the VM Terminal, run the bootstrap script:"
log "   curl -fsSL $BOOTSTRAP_URL | bash"
log "   or ssh into the machine:"
log "   ssh admin@\$(tart ip $VM_NAME)"
log ""
log "   Note: Bootstrap uses HTTPS (no SSH key needed for installation)"
log "   The script will show instructions for switching to SSH afterward"
log ""
log "4. Test the installation:"
log "   - Verify all tools installed: brew list"
log "   - Check symlinks: ls -la ~ | grep '^l'"
log "   - Test Neovim: nvim"
log "   - Test aliases: jfzf, mru, etc."
log ""
log "5. When done, delete the VM:"
log "   tart delete $VM_NAME"
