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
  - [x] **zoxide**: Not adding at this stage.
    - **Decision**: Will add zoxide as needed when implementing shell functionality from dotfilesold
    - **Rationale**: Keep initial setup minimal, add when specific navigation features are migrated
  - [x] **pnpm**: Not using. npm will suffice.
  - [x] **Utilities**: Not adding at this stage.
    - **Decision**: Will add jq, coreutils, wget, entr as needed when implementing shell functionality from dotfilesold
    - **Rationale**: Keep initial setup minimal, add utilities when specific use cases arise
  - [x] **Global Packages**: Not adding at this stage.
    - **Decision**: Will add Typescript and other global packages as needed when implementing workflows from dotfilesold
    - **Rationale**: Keep initial setup minimal, add when specific development workflows require them

## Phase 3: Configure Shell
- [x] **Setup Zsh environment**
  - [x] Create ~/.dotfiles/zsh/ directory structure (reproduced from dotfilesold)
  - [x] Reproduce legacy Zsh files: `zlogin.symlink`, `zshenv.symlink`, `zshprofile.symlink`
  - [ ] Configure Antidote plugin manager
  - [ ] **Port Core Customizations (from dotfilesold)**:
    - [x] `auto_cd`, `autopushd`, and `HIST_VERIFY` options
    - [x] Case-insensitive tab completion (`matcher-list`)
    - [x] Setup `jd` (~/.dotfiles) and `jp` (~/projects) navigation aliases
    - [x] Implementation of Global Aliases (`G`, `E`, `V`)
    - [x] Prefix-based history search (Up/Down arrow)
    - [x] Keybindings: `Ctrl+G` (push-line) and `Ctrl+H` (run-help)
  - [ ] **Analyze & Migrate Shell Aliases**:
    - [ ] Full analysis of all aliases in `dotfilesold/aliases`
    - [ ] Clean up and categorize (essential vs legacy)
    - [ ] Port to `zsh/aliases.zsh`
  - [ ] Setup basic aliases and environment variables
- [ ] **README: Update Shell Configuration section** (Zsh setup, plugins, prompt)

## Phase 4: Neovim Migration (Porting from dotfilesold)
- [ ] **Core Editor Foundation**
  - [ ] Install Neovim via brew and setup lazy.nvim
  - [ ] Implement Cursor/Terminal detection for conditional loading
- [ ] **Essential Feature Porting**
  - [ ] **Fuzzy Finder**: Setup Telescope (modern replacement for hzf/fzf in vim)
  - [ ] **File Explorer**: Setup neo-tree or nvim-tree
  - [ ] **Git Integration**: Setup gitsigns and lazygit/fugitive
  - [ ] **Syntax Highlighting**: Setup Treesitter
- [ ] **Customization Analysis**
  - [ ] Full analysis of `dotfilesold/config/nvim/` (init.vim, startup/, etc.)
  - [ ] Identify and port "must-have" legacy keybindings
  - [ ] Identify and port essential abbreviations and utility functions
- [ ] **README: Update Neovim section** (installation, basic usage, modes)

## Phase 5: Handpicked Tools (Discuss & Implement Each)
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

## Phase 6: Configuration Files & Symlinks
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

## Phase 7: Tool Integration & Customization
- [ ] **ripgrep + fzf integration** (Neovim Telescope, shell functions)
- [ ] **Neovim plugins setup** (lazy.nvim config, essential plugins)
- [ ] **Cursor/Terminal detection** (environment detection, conditional config)
- [ ] **Shell aliases & functions** (productivity shortcuts, tool integrations)
- [ ] **README: Integration section** (how tools work together, workflows)

## Phase 8: Testing & Refinement
- [ ] **Test each tool individually** (verify installation, basic functionality)
- [ ] **Test integrations** (tools working together: fzf+ripgrep+Neovim)
- [ ] **Performance testing** (startup times, responsiveness)
- [ ] **Edge case testing** (missing dependencies, network issues)
- [ ] **README: Testing & Troubleshooting** (common issues, performance tips)

## Phase 9: Finalization
- [ ] **Clean up and optimize** (remove unused code, optimize performance)
- [ ] **Final verification** (clean macOS install test)
- [ ] **README: Complete documentation** (final polish, maintenance guide)

## Current Focus
- **Starting Point**: Phase 3: Configure Shell
- **Methodology**: Discuss tool → implement → test → document in README
- **Documentation**: README updated after each major implementation

## README Update Workflow
1. Implement a tool/feature
2. Test it works
3. Document in README immediately
4. Move to next tool/feature
