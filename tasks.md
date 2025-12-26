# Dotfiles Implementation Tasks

## Core Approach
- **Install Script First**: Create reusable install.sh with functions to avoid repetition
- **Symlinking Strategy**: Config files live in ~/.dotfiles, install.sh creates symlinks
- **Handpicked Tools**: Discuss each tool, its purpose, install + customize with dedicated files
- **Living Documentation**: README.md updated after each major implementation

## Phase 1: Core Infrastructure
- [x] **Create installation script foundation** (reusable functions: log(), is_macos(), etc.)
- [x] **Setup directory structure** (./installation flat folder)
- [x] **Initialize tools.json** (handpicked tools with dependencies)
- [x] **Create basic logging system** (~/Library/Logs/dotfiles/ with dual output)
- [x] **README: Project Overview** (what this dotfiles does, requirements, quick start)

## Phase 2: Tool Reconciliation (Decide & Finalize)
- [ ] **Discuss & decide on each tool from dotfilesold**:
  - [x] **fzf**: Keep. Purpose, usage, and shell integration.
  - [x] **starship**: Keep. Prompt choice and customization.
  - [x] **iterm2**: Keep. App management and profile syncing.
  - [x] **karabiner-elements**: Keep. Key mapping strategy.
  - [x] **rectangle**: Keep (replacing Spectacle). Window management.
  - [x] **maccy**: Keep (chosen over Flycut). Clipboard management.
  - [ ] **zoxide**: (Replacing `fasd`) Purpose and shell hooks.
  - [ ] **pnpm**: (Replacing `yarn`) Package management strategy.
  - [ ] **Utilities**: `jq`, `coreutils`, `wget`, `entr`. Keep.
  - [ ] **Cloud Tools**: `google-cloud-sdk`. Keep.
  - [ ] **Global Packages**: PM2, Typescript, etc. Keep.

## Phase 3: Handpicked Tools (Discuss & Implement Each)
- [ ] **Homebrew**
  - [ ] Discuss: package manager purpose, why brew vs others
  - [ ] Install: via install.sh with PATH setup
  - [ ] Configure: basic brew setup and maintenance
  - [ ] **README: Update Homebrew section** (installation, usage, maintenance)
- [ ] **Git**
  - [ ] Discuss: version control, SSH setup, global config
  - [ ] Install: via install.sh
  - [ ] Configure: SSH keys, global config file, aliases
  - [ ] **README: Update Git section** (setup, SSH keys, common commands)
- [ ] **ripgrep**
  - [ ] Discuss: search tool, why ripgrep vs ag, performance benefits
  - [ ] Install: via install.sh
  - [ ] Configure: basic usage, integration points
  - [ ] **README: Update ripgrep section** (usage examples, Neovim integration)
- [ ] **fzf**
  - [ ] Discuss: fuzzy finder, integration with other tools
  - [ ] **Phase 1: Core Setup (1-2 hours)** - Get basic fzf working with Ctrl+T/Ctrl+R
    - [x] Install fzf via tools.json (already added)
    - [x] Source fzf key-bindings.zsh in zshrc (like dotfilesold)
    - [ ] Test basic functionality (Ctrl+T for files, Ctrl+R for history)
  - [ ] **Phase 2: Function Analysis (2-3 hours)** - Categorize 15+ fzf functions from dotfilesold
    - [ ] **Essential (Keep & Modernize)**: fag(), fa(), fbr(), fshow(), fstash()
    - [ ] **Browser Integration**: chromehistory(), chromebookmarks() (Chrome-specific)
    - [ ] **Developer Tools**: fman(), factivate(), jfzf()
    - [ ] **Theme/Utilities**: fzf-chth(), preview helpers
    - [ ] **Questionable/Complex**: Advanced git integrations
  - [ ] **Phase 3: Core Functions Migration (2-4 hours)** - Port 5-7 essential functions
    - [ ] fag() - ripgrep search (main search tool)
    - [ ] fa() - file finder with preview
    - [ ] fbr() - git branch switching
    - [ ] fshow() - git log browser
    - [ ] fman() - man page search
    - [ ] Modernize ripgrep calls, update file paths from $DOTFILES to ~/.dotfiles
  - [ ] **Phase 4: Browser Integration (Optional - 1-2 hours)** - Chrome history/bookmarks
    - [ ] chromehistory() - browse Chrome history (check modern Chrome format)
    - [ ] chromebookmarks() - browse Chrome bookmarks (Ruby script)
  - [ ] **Phase 5: Polish & Documentation (1 hour)**
    - [ ] Update README.md with fzf usage examples
    - [ ] Mark tasks complete
    - [ ] Test all functions work together

## Phase 4: Shell & Editor Foundation
- [ ] **Zsh + Antidote**
  - [ ] Discuss: why Zsh, plugin management approach
  - [ ] Install: Zsh via brew, Antidote setup
  - [ ] Configure: plugin loading, basic aliases, environment
  - [ ] **README: Update Shell section** (Zsh setup, plugins, customization)
- [ ] **Neovim + lazy.nvim**
  - [ ] Discuss: editor choice, Lua migration, conditional loading
  - [ ] Install: Neovim via brew, lazy.nvim setup
  - [ ] Configure: basic Lua structure, Cursor/Terminal detection
  - [ ] **README: Update Neovim section** (installation, basic usage, modes)
- [x] **Setup .zshrc foundation** (Add `eval "$(starship init zsh)"` to `.zshrc`)
- [ ] **Integrate mise into shell prompt** (Add `eval "$(mise activate zsh)"` to `.zshrc`)
- [ ] **Restart terminal or source config** (Required for mise to fully integrate)

## Phase 5: Configuration Files & Symlinks
- [ ] **Git configuration** (create ~/.dotfiles/config/git/ files, symlink logic)
- [ ] **Shell configuration** (create ~/.dotfiles/config/zsh/ files, symlink logic)
- [ ] **Neovim configuration** (create ~/.dotfiles/config/nvim/ Lua files, symlink logic)
- [ ] **iTerm2 configuration**
  - [ ] **DISCUSS FIRST**: What iTerm configuration do we need? Base16 colors integration, profiles, shell integration, key bindings?
  - [ ] Create ~/.dotfiles/config/iterm2/ directory structure
  - [ ] Base16 color schemes (matching Neovim themes for consistency)
  - [ ] iTerm2 profiles configuration and symlinking
  - [ ] Shell integration setup (optional - discuss if needed)
- [x] **Test all symlinks** (verify symlinks work, configs load correctly)
- [ ] **README: Configuration section** (symlinking explanation, config locations)

## Phase 6: Tool Integration & Customization
- [ ] **ripgrep + fzf integration** (Neovim Telescope, shell functions)
- [ ] **Neovim plugins setup** (lazy.nvim config, essential plugins)
- [ ] **Cursor/Terminal detection** (environment detection, conditional config)
- [ ] **Shell aliases & functions** (productivity shortcuts, tool integrations)
- [ ] **README: Integration section** (how tools work together, workflows)

## Phase 7: Testing & Refinement
- [ ] **Test each tool individually** (verify installation, basic functionality)
- [ ] **Test integrations** (tools working together: fzf+ripgrep+Neovim)
- [ ] **Performance testing** (startup times, responsiveness)
- [ ] **Edge case testing** (missing dependencies, network issues)
- [ ] **README: Testing & Troubleshooting** (common issues, performance tips)

## Phase 8: Finalization
- [ ] **Clean up and optimize** (remove unused code, optimize performance)
- [ ] **Final verification** (clean macOS install test)
- [ ] **README: Complete documentation** (final polish, maintenance guide)

## Current Focus
- **Starting Point**: Phase 2: Tool Reconciliation (Decide & Finalize)
- **Methodology**: Discuss tool → implement → test → document in README
- **Documentation**: README updated after each major implementation

## README Update Workflow
1. Implement a tool/feature
2. Test it works
3. Document in README immediately
4. Move to next tool/feature
