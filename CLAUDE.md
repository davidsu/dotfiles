# Dotfiles Project Rules

## Project Overview

Migrating and modernizing dotfiles from old implementation:
- **Source**: `dotfilesold` branch (Vimscript, vim-plug, ag, fnm)
- **Target**: `master` branch at `~/.dotfiles/` (Pure Lua, lazy.nvim, ripgrep, mise)
- **Platform**: macOS only (remove all Linux compatibility code)
- **Goal**: Keep functionality, modernize implementation, clean up cruft

## Critical Rules

### 1. Don't Rush to Implementation
When user asks a question, **answer the question** - don't implement anything unless explicitly asked.

**Bad**: User asks "what colorscheme did I use?" → You immediately add a colorscheme plugin
**Good**: User asks "what colorscheme did I use?" → You check dotfilesold and tell them

### 2. Check Dotfilesold First
Before implementing ANY feature, check how it was done in the `dotfilesold` branch.

Don't assume or guess - look at the actual old code. You can reference files on the dotfilesold branch directly.

### 3. Ask User to Help Debug
When encountering visual/UI issues you can't diagnose from code alone, ask user to run diagnostic commands:
- Color/highlight issues: Ask user to run `:Inspect` on the affected character
- Syntax issues: Ask for `:TSHighlightCapturesUnderCursor`
- Option issues: Ask for `:set option?`

Don't guess - get data first.

### 4. Verify External Resources
Before suggesting GitHub repos, npm packages, or external resources:
- Search to verify they exist
- Check they're still maintained
- Find the actual canonical source

### 5. MANDATORY: Read Local Documentation Before Neovim Implementation
**CRITICAL BLOCKING REQUIREMENT**: Before implementing ANY Neovim feature or plugin configuration, you MUST read the relevant local documentation first.

**For Neovim Plugins:**
1. **BEFORE** implementing or configuring ANY plugin feature, read the plugin's local help files
2. **Location**: `~/.local/share/nvim/lazy/<plugin-name>/`
   - Help files: `doc/*.txt`
   - README: `README.md`
   - Source code: `lua/` (for defaults and examples)
3. Use the Read tool to verify options, configuration format, and correct parameter names
4. **Only after** reading local docs should you proceed with implementation

**For Neovim Native Features:**
1. **BEFORE** implementing ANY native Neovim feature (options, keymaps, autocommands, etc.), read Neovim's local documentation
2. **Location**: Neovim runtime documentation
   - Help files: Use `:help <topic>` or read from Neovim's help system
   - Runtime docs: `/usr/local/share/nvim/runtime/doc/` (or similar)
3. Verify correct API usage, option names, and function signatures from local docs

**Why this is mandatory:**
- Prevents using deprecated/wrong options (like `jump_to_single_result` vs `jump1`)
- Ensures version compatibility with installed plugins
- Faster and more accurate than web searches
- Works offline

**Only use web searches after reading local docs if:**
- Local docs don't exist or are incomplete
- You need clarification beyond what local docs provide
- You're researching whether to add a NEW plugin (not yet installed)

### 6. Keep Documentation and Installation Script Updated
**CRITICAL**: Always update both documentation AND installation files when adding tools or features.

**Documentation** - All `.md` files must remain up to date:
- **Project root**: `~/.dotfiles/*.md` (README.md, tasks.md, planning.md, etc.)
- **Neovim docs**: `~/.dotfiles/config.home.symlink/nvim/*.md`

**Installation** - Keep installation script in sync:
- When adding a tool via Homebrew: Add to `installation/tools.json`
- When creating files that need symlinking to home directory: Use `*.symlink` naming convention (handled automatically by installation script)
- When adding dependencies between tools: Update tool dependencies in `tools.json`

**Why this matters**:
- Installation script enables easy setup on new computers
- Documentation prevents losing track of what's been implemented
- Both are essential for the dotfiles to be usable and maintainable

Update documentation and installation files IMMEDIATELY after implementing features, not later.

### 7. NEVER Commit Without User Approval
**CRITICAL**: Do NOT create commits unless explicitly told to by the user.

- After making changes, STOP and let the user review
- Only run `git commit` when user says "commit" or similar
- User wants the opportunity to test and verify changes first
- If user asks "can you commit?", that means ask for permission, NOT commit immediately

**Bad**: Making changes → Immediately running `git commit`
**Good**: Making changes → Telling user "Changes are ready, let me know when you want to commit"

### 8. Consider Error Handling and Edge Cases
When implementing file-based features or persistent state, proactively think about failure modes:

**Common edge cases to consider:**
- File corruption (malformed data, binary garbage)
- Race conditions (multiple instances writing simultaneously)
- Write failures (disk full, permissions)
- Missing files or directories

**Approach:**
1. First implement the happy path
2. Then ask user: "What about edge cases like corruption/race conditions?"
3. Add error handling with `pcall()` or similar
4. Fail gracefully (silent failures for non-critical features, user warnings for critical ones)

**Example**: MRU file tracking
- File corruption → `pcall()` around `io.lines()`, start fresh on error
- Write failure → Silent fail, user just misses one entry
- Race conditions → Acceptable for personal dotfiles (document "last writer wins")

Don't over-engineer, but DO ask about failure modes before considering a feature "done".
