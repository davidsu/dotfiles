# Dotfiles Planning Strategy

## Overview
This document outlines the comprehensive planning strategy for rebuilding the dotfiles configuration from scratch, based on the existing `dotfilesold` setup while modernizing and simplifying the development environment.

## Core Principles
- **macOS Only**: Optimized exclusively for macOS, no Linux support
- **Pure Lua**: Eliminate all Vimscript, use Lua exclusively for Neovim
- **Conditional Neovim**: Lean mode for Cursor IDE, full-featured mode for terminal
- **Modern Tools**: ripgrep over ag, current best practices
- **Robust Installation**: Smart install script with error handling and dependency management

## Architecture Overview

```
~/.dotfiles/
├── README.md                    # Comprehensive setup & usage guide (ALWAYS KEEP UPDATED)
├── install.sh                   # Smart installation script
├── tools.yaml                   # Tool & dependency configuration
├── config.home.symlink/         # Configuration directory (links to ~/.config)
│   ├── zsh/                     # Zsh configuration (Antidote)
│   ├── nvim/
│   │   ├── init.lua             # Main entry point
│   │   ├── lua/
│   │   │   ├── core/           # Core functionality
│   │   │   ├── plugins/        # Plugin configurations
│   │   │   ├── ui/             # UI/UX settings
│   │   │   └── utils/          # Utility functions
│   │   └── ftplugin/           # Filetype-specific settings
│   ├── iterm2/                 # iTerm2 profiles & settings
│   ├── git/                    # Git configuration
│   └── karabiner/              # Keyboard customization
├── zsh/                         # Modular Zsh configuration
│   ├── zshrc.home.zsh           # Links to ~/.zshrc
│   ├── zshprofile.home.zsh      # Links to ~/.zshprofile
│   └── ...                      # Other .home.zsh files
├── scripts/
│   ├── install/                # Installation helpers
│   │   ├── dependencies.sh     # Dependency management
│   │   ├── tools.sh            # Workflow tools
│   │   └── verify.sh           # Post-install verification
│   └── utils/                  # Runtime utilities
└── Brewfile                    # Homebrew dependencies
```

## README.md Requirements

The `README.md` must **ALWAYS remain up-to-date** and serve as the comprehensive guide for this dotfiles setup. It must include:

### **Comprehensive Content**
- **Installation Guide**: Complete setup instructions for new machines
- **Tool Documentation**: All tools, their usage, and integration points
- **Workflow Guide**: Daily development workflows and shortcuts
- **Customization**: How to modify and extend configurations
- **Troubleshooting**: Common issues and their solutions
- **Maintenance**: Update procedures and breaking change handling

**README.md serves as the single source of truth for all documentation.**

## Component Specifications

### 1. Neovim Configuration (Pure Lua)
- **Conditional Loading**: Detect Cursor vs Terminal environment
- **Cursor Mode**: Minimal plugins, fast startup, basic functionality
- **Terminal Mode**: Full feature set including smooth scrolling, advanced plugins
- **Plugin Manager**: lazy.nvim (modern, fast, Lua-native)
- **Structure**: Modular Lua files with clear separation of concerns

### 2. Terminal & Editor Integration
- **iTerm2**: Keep current setup with modern configuration
- **Cursor Detection**: Environment variable or process detection
- **Feature Branching**: Different plugin sets based on context

### 3. Search & Navigation
- **Primary Tool**: ripgrep (rg) - replace all ag usage
- **Migration**: Update scripts and configurations to use ripgrep syntax
- **Integration**: Telescope, fzf, and other tools configured for ripgrep

### 4. Shell Environment
- **Zsh**: Modern configuration with Antidote plugin manager
- **Dependencies**: Clear distinction between workflow tools and dependencies
- **Performance**: Fast startup, lazy loading where appropriate

### 5. Development Tools
- **Language Managers**: rtx (multi-language version manager)
- **Package Managers**: Modern npm/pnpm over legacy yarn
- **Build Tools**: Current versions, macOS-optimized

## Installation Script Requirements

### Tool & Dependency Configuration

Tools and dependencies are defined in `tools.yaml` for explicit relationship tracking:

```yaml
tools:
  neovim:
    type: workflow
    dependencies: [cmake, ninja, gettext, libtool, automake, pkg-config]
    description: "Primary editor"

  cmake:
    type: dependency
    required_by: [neovim]
    description: "Build system required by Neovim"
```

**Benefits:**
- **Explicit relationships**: Each dependency shows which tool requires it
- **Clear separation**: Distinguishes workflow tools from dependencies
- **Self-documenting**: Configuration serves as installation documentation
- **Maintainable**: Single source of truth for tool definitions

### Logging & Output
- **Dual output**: All messages written to both stdout and `~/Library/Logs/dotfiles/install.log`
- **Error tracking**: Errors written to both stderr and `~/Library/Logs/dotfiles/install_errors.log`
- **Timestamped logs**: All log entries include timestamps for troubleshooting
- **Progress tracking**: Installation progress clearly logged for review

### Installation Flow
1. **Pre-flight Checks**: Verify macOS version, existing tools (logged to ~/Library/Logs/dotfiles/install.log)
2. **Parse Configuration**: Load `tools.yaml` and build dependency tree
3. **Dependency Resolution**: Install dependencies first (shows which tool requires each)
4. **Workflow Tools**: Install user-facing development tools
5. **Configuration**: Symlink dotfiles, apply settings
6. **Verification**: Test installations, report issues
7. **Post-install**: Optional tools and customizations
8. **Log Summary**: Display installation summary and log file location (`~/Library/Logs/dotfiles/`)

### Error Handling & Recovery
- Continue on individual tool failures
- Clear error messages with suggested fixes
- Rollback mechanisms for critical failures
- **Comprehensive logging**: All messages written to log file in addition to stdout/stderr
- **Installation log**: `~/Library/Logs/dotfiles/install.log` captures full installation process
- **Error log**: `~/Library/Logs/dotfiles/install_errors.log` for troubleshooting

## Migration Strategy

### From dotfilesold
- **Keep**: Core functionality, proven configurations
- **Update**: Modern tool versions, Lua conversion
- **Remove**: Legacy Vimscript, ag dependencies, Linux-specific code
- **Refactor**: Conditional loading for Cursor compatibility

### Breaking Changes
- Scripts using `ag` → migrate to `ripgrep`
- Vimscript configurations → pure Lua
- Plugin management → lazy.nvim
- Environment detection → Cursor-aware loading

## Success Metrics
- **Installation**: Single command setup (`./install.sh`)
- **Performance**: Neovim startup < 100ms (Cursor), < 200ms (Terminal)
- **Compatibility**: Seamless Cursor integration
- **Documentation**: Always up-to-date README.md with comprehensive usage guides
- **Maintainability**: Clear code structure, comprehensive documentation
- **Reliability**: Robust error handling, graceful degradation

## Risk Mitigation
- **Testing**: Comprehensive testing on clean macOS installs
- **Backups**: Preserve dotfilesold as reference
- **Gradual Migration**: Component-by-component approach
- **Documentation**: Detailed guides for each component
