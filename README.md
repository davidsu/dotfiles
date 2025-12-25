# Dotfiles

A modern, performance-focused dotfiles configuration optimized exclusively for macOS.

## Prerequisites

- **macOS**: This configuration is macOS-only.
- **Homebrew**: The installation script will attempt to install Homebrew if it's missing.

## Installation

To set up your environment, clone this repository and run the installation script:

```bash
./installation/install.sh
```

The script will:
1. Perform pre-flight system checks.
2. Bootstrap `mise` and `node` as the primary runtime managers.
3. Install and verify all tools defined in `installation/tools.json`.

## Architecture

- **`installation/`**: Contains the bootstrap and dependency management scripts.
- **`tools.json`**: The single source of truth for all tools and dependencies.
- **`planning.md`**: Detailed technical specification and project goals.
- **`tasks.md`**: Current development progress and roadmap.

## Logs

Installation logs are captured in `~/Library/Logs/dotfiles/install.log`.
Error logs are captured in `~/Library/Logs/dotfiles/install_errors.log`.

