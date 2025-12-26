# Dotfiles

A modern, performance-focused dotfiles configuration optimized exclusively for macOS.

## Prerequisites

- **macOS**: This configuration is macOS-only.
- **Homebrew**: The installation script will attempt to install Homebrew if it's missing.

## Installation

To set up your environment, clone this repository into `~/.dotfiles` and run the installation script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./installation/install.sh
```

The script will:
1. Perform pre-flight system checks.
2. Bootstrap `mise` and `node` as the primary runtime managers.
3. Install and verify all tools defined in `installation/tools.json`.

## Architecture

- **`installation/`**: Contains the bootstrap and dependency management scripts.
- **`config/`**: Configuration files symlinked to system locations (`.config`, `Library/Preferences`, etc.).
- **`tools.json`**: The single source of truth for all tools and dependencies.
- **`planning.md`**: Detailed technical specification and project goals.
- **`tasks.md`**: Current development progress and roadmap.

## Keyboard Customization (Karabiner-Elements)

This dotfiles includes comprehensive keyboard remappings via Karabiner-Elements:

### Navigation Layer
- **Fn + H/J/K/L** → Arrow keys (Vim-style navigation)
- **Fn + N/M** → Home/End keys

### Volume Controls (FC660C Keyboard)
- **Fn + 9** → Volume Down
- **Fn + 0** → Volume Up

### Smart Modifier Keys
- **Caps Lock**: Tap for Escape, hold for Left Control
- **Return**: Tap for Return, hold for Right Control

### Function Key Remapping
- **F1/F2** → Display brightness controls
- **F3/F4** → Mission Control/Launchpad
- **F5/F6** → Keyboard illumination
- **F7/F8/F9** → Media controls (rewind/play/fast-forward)
- **F10/F11/F12** → Volume controls

### Device-Specific Configuration
- Optimized for FC660C mechanical keyboard
- Custom Fn function key mappings

## Logs

Installation logs are captured in `~/Library/Logs/dotfiles/install.log`.
Error logs are captured in `~/Library/Logs/dotfiles/install_errors.log`.

