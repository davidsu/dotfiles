# Dotfiles Implementation Tasks

## Core Approach
- **Install Script First**: Create reusable install.sh with functions to avoid repetition
- **Symlinking Strategy**: Config files live in ~/.dotfiles, install.sh creates symlinks
- **Handpicked Tools**: Discuss each tool, its purpose, install + customize with dedicated files
- **Living Documentation**: README.md updated after each major implementation

## Core Infrastructure
- [x] **Create installation script foundation** (reusable functions: log(), is_macos(), etc.)
- [x] **Setup directory structure** (./installation flat folder)
- [x] **Initialize tools.json** (handpicked tools with dependencies)
- [x] **Create basic logging system** (~/Library/Logs/dotfiles/ with dual output)
- [x] **README: Project Overview** (what this dotfiles does, requirements, quick start)

## Tool Reconciliation (Decide & Finalize)
- [ ] **Discuss & decide on each tool from dotfilesold**:
  - [x] **fzf**: Keep. Purpose, usage, and shell integration.
  - [x] **starship**: Keep. Prompt choice and customization.
  - [x] **iterm2**: Keep. App management and profile syncing.
  - [x] **karabiner-elements**: Keep. Key mapping strategy.
  - [x] **rectangle**: Keep (replacing Spectacle). Window management.
  - [x] **maccy**: Keep (chosen over Flycut). Clipboard management.
  - [x] **zoxide**: Added (modern replacement for fasd)
    - **Decision**: Using zoxide for smart directory navigation with fzf integration
    - **Implementation**: Installed via tools.json, initialized in zsh/zoxide.zsh
  - [x] **pnpm**: Not using. npm will suffice.
  - [x] **Utilities**: Not adding at this stage.
    - **Decision**: Will add jq, coreutils, wget, entr as needed when implementing shell functionality from dotfilesold
    - **Rationale**: Keep initial setup minimal, add utilities when specific use cases arise
  - [x] **Global Packages**: Not adding at this stage.
    - **Decision**: Will add Typescript and other global packages as needed when implementing workflows from dotfilesold
    - **Rationale**: Keep initial setup minimal, add when specific development workflows require them

## Neovim Migration (Porting from dotfilesold)
- [x] **Core Editor Foundation**
  - [x] Install Neovim via brew and setup lazy.nvim
  - [x] Implement Cursor/Terminal detection for conditional loading
- [x] **Essential Feature Porting**
  - [x] **Fuzzy Finder**: Setup fzf.vim with ripgrep integration and bat-powered previews
  - [x] **File Explorer**: Setup neo-tree or nvim-tree (nvim-tree already configured)
  - [x] **Git Integration**: Setup gitsigns and lazygit/fugitive (gitsigns, fugitive, rhubarb configured)
  - [x] **Syntax Highlighting**: Setup Treesitter (installed with gruvbox colorscheme)
  - [x] **Colorscheme**: Setup gruvbox (matching dotfilesold's darktooth variant)
- [ ] **Customization Analysis**
  - [ ] Full analysis of `dotfilesold/config/nvim/` (init.vim, startup/, etc.)
  - [x] **Identify and port "must-have" legacy keybindings**:
    - [x] `q` to close help/quickfix/fugitive buffers
    - [x] `:h` abbreviation to open help in new tab
    - [x] `m,` and `sa` for alternate file switching
    - [x] `gb` for git blame
    - [x] `\a` for ripgrep search with fzf preview
  - [ ] Identify and port essential abbreviations and utility functions
- [ ] **README: Update Neovim section** (installation, basic usage, modes)

## Configure Shell
- [x] **Setup Zsh environment**
  - [x] Create ~/.dotfiles/zsh/ directory structure (reproduced from dotfilesold)
  - [x] Reproduce legacy Zsh files: `zlogin.home.zsh`, `zshenv.home.zsh`, `zshprofile.home.zsh`
  - [ ] Configure Antidote plugin manager
  - [ ] **Port Core Customizations (from dotfilesold)**:
    - [x] `auto_cd`, `autopushd`, and `HIST_VERIFY` options
    - [x] Case-insensitive tab completion (`matcher-list`)
    - [x] Setup `jd` (~/.dotfiles) and `jp` (~/projects) navigation aliases
    - [x] Implementation of Global Aliases (`G`, `E`, `V`)
    - [x] Prefix-based history search (Up/Down arrow)
    - [x] Keybindings: `Ctrl+G` (push-line) and `Ctrl+H` (run-help)
  - [ ] **Analyze & Migrate Legacy Configuration (from dotfilesold)**:
    - [x] `@/Users/thistooshallpass/Developer/dotfilesold/ag-helper-functions.sh`: Legacy search helpers (ported to ripgrep version in aliases.zsh)
    - [x] `@/Users/thistooshallpass/Developer/dotfilesold/aliases`: Core command shortcuts
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/bindkey`: Custom Zsh keybindings
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/fzf.zsh`: FZF-specific shell integrations
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/history`: History behavior and management
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/lessconfig`: Pager configuration
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/linuxUtils`: (Skip? macOS focus)
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/loadall`: Bootstrap logic
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/misc`: Miscellaneous shell settings
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/mru`: Most Recently Used file tracking
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/prompt`: Prompt configuration (Starship is current, check for custom logic)
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/theme`: Visual settings
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/tmp`: Temporary file management
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/variables`: Environment variables
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/wixstuff`: Work-specific or specialized tools
    - [ ] `@/Users/thistooshallpass/Developer/dotfilesold/zshhooks`: Shell lifecycle hooks
  - [x] **Analyze & Migrate Shell Aliases**:
    - [x] Full analysis of all aliases in `dotfilesold/aliases`
    - [x] Clean up and categorize (essential vs legacy)
    - [x] Port to `zsh/aliases.zsh`
  - [x] Setup basic aliases and environment variables
- [ ] **README: Update Shell Configuration section** (Zsh setup, plugins, prompt)

## Handpicked Tools (Discuss & Implement Each)
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
- [x] **ripgrep**
  - [x] Install: via tools.json
  - [x] Configure: integrated with fzf.vim for search in Neovim
  - [ ] **README: Update ripgrep section** (usage examples, Neovim integration)
- [x] **bat**
  - [x] Install: via tools.json (dependency of neovim)
  - [x] Configure: automatic syntax highlighting in fzf previews
  - [ ] **README: Update bat section** (usage with fzf, preview examples)
- [ ] **fzf**
  - [ ] Discuss: fuzzy finder, integration with other tools
  - [ ] **Core Setup (1-2 hours)** - Get basic fzf working with Ctrl+T/Ctrl+R
    - [x] Install fzf via tools.json (already added)
    - [x] Source fzf key-bindings.zsh in zshrc (like dotfilesold)
    - [ ] Test basic functionality (Ctrl+T for files, Ctrl+R for history)
  - [ ] **Function Analysis (2-3 hours)** - Categorize 15+ fzf functions from dotfilesold
    - [x] **Essential (Keep & Modernize)**:
      - [x] fag() - Search with ripgrep + fzf, open in nvim
      - [x] jfzf() - Directory jumping with zoxide + fzf (alias: zi)
      - [x] chromehistory() - Browse Chrome history with fzf
      - [ ] fa() - File finder with preview
      - [ ] fbr() - Git branch switching
      - [ ] fshow() - Git commit browser
      - [ ] fstash() - Git stash browser
    - [ ] **Browser Integration**: chromehistory(), chromebookmarks() (Chrome-specific)
    - [ ] **Developer Tools**: fman(), factivate(), jfzf()
    - [ ] **Theme/Utilities**: fzf-chth(), preview helpers
    - [ ] **Questionable/Complex**: Advanced git integrations
  - [ ] **Core Functions Migration (2-4 hours)** - Port 5-7 essential functions
    - [ ] fag() - ripgrep search (main search tool)
    - [ ] fa() - file finder with preview
    - [ ] fbr() - git branch switching
    - [ ] fshow() - git log browser
    - [ ] fman() - man page search
    - [ ] Modernize ripgrep calls, update file paths from $DOTFILES to ~/.dotfiles
  - [ ] **Browser Integration (Optional - 1-2 hours)** - Chrome history/bookmarks
    - [ ] chromehistory() - browse Chrome history (check modern Chrome format)
    - [ ] chromebookmarks() - browse Chrome bookmarks (Ruby script)
  - [ ] **Polish & Documentation (1 hour)**
    - [ ] Update README.md with fzf usage examples
    - [ ] Mark tasks complete
    - [ ] Test all functions work together

## Configuration Files & Symlinks
- [ ] **Git configuration** (create ~/.dotfiles/config.home.symlink/git/ files, symlink logic)
- [ ] **Shell configuration** (create ~/.dotfiles/config.home.symlink/zsh/ files, symlink logic)
- [ ] **Neovim configuration** (create ~/.dotfiles/config.home.symlink/nvim/ Lua files, symlink logic)
- [ ] **iTerm2 configuration**
  - [ ] **DISCUSS FIRST**: What iTerm configuration do we need? Base16 colors integration, profiles, shell integration, key bindings?
  - [ ] Create ~/.dotfiles/config.home.symlink/iterm2/ directory structure
  - [ ] Base16 color schemes (matching Neovim themes for consistency)
  - [ ] iTerm2 profiles configuration and symlinking
  - [ ] Shell integration setup (optional - discuss if needed)
- [x] **Test all symlinks** (verify symlinks work, configs load correctly)
- [x] **README: Configuration section** (symlinking explanation, config locations)
- [x] **Remove broken symlinks and self-heal** (verified naming convention and installation script)

## Tool Integration & Customization
- [ ] **ripgrep + fzf integration** (Neovim Telescope, shell functions)
- [ ] **Neovim plugins setup** (lazy.nvim config, essential plugins)
- [ ] **Cursor/Terminal detection** (environment detection, conditional config)
- [ ] **Shell aliases & functions** (productivity shortcuts, tool integrations)
- [ ] **README: Integration section** (how tools work together, workflows)

## Testing & Refinement
- [ ] **Test each tool individually** (verify installation, basic functionality)
- [ ] **Test integrations** (tools working together: fzf+ripgrep+Neovim)
- [ ] **Performance testing** (startup times, responsiveness)
- [ ] **Edge case testing** (missing dependencies, network issues)
- [ ] **README: Testing & Troubleshooting** (common issues, performance tips)

## Finalization
- [ ] **Clean up and optimize** (remove unused code, optimize performance)
- [ ] **Final verification** (clean macOS install test)
- [ ] **README: Complete documentation** (final polish, maintenance guide)

## Current Focus
- **Starting Point**: Neovim Migration (Porting from `dotfilesold`)
- **Methodology**: Analyze legacy file → Discuss tool/logic → implement modern version → test → document
- **Documentation**: README updated after each major implementation

## README Update Workflow
1. Implement a tool/feature
2. Test it works
3. Document in README immediately
4. Move to next tool/feature
