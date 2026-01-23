# Dotfiles Project Rules

## Project Overview

Migrating and modernizing dotfiles from old implementation:

- **Source**: `dotfilesold` branch (Vimscript, vim-plug, ag, fnm)
- **Target**: `master` branch at `~/.dotfiles/` (Pure Lua, lazy.nvim, ripgrep, mise)
- **Platform**: macOS only (remove all Linux compatibility code)
- **Goal**: Keep functionality, modernize implementation, clean up cruft

## Auto-Load Skills

**When working on Neovim configuration or Lua code for Neovim**, load the neovim skill first:

- Run: `/neovim` to load Neovim-specific rules (Lua patterns, local docs, debugging)

## Critical Rules

### 1. Don't Rush to Implementation

When user asks a question, **answer the question** - don't implement anything unless explicitly asked.

**Bad**: User asks "what colorscheme did I use?" → You immediately add a colorscheme plugin
**Good**: User asks "what colorscheme did I use?" → You check dotfilesold and tell them

### 2. Verify External Resources

Before suggesting GitHub repos, npm packages, or external resources:

- Search to verify they exist
- Check they're still maintained
- Find the actual canonical source

### 3. Keep Documentation and Installation Script Updated

**CRITICAL**: Always update both documentation AND installation files when adding tools or features.

**Documentation** - All `.md` files must remain up to date:

- **Project root**: `~/.dotfiles/*.md` (README.md, tasks.md, planning.md, etc.)

**Installation** - Keep installation script in sync:

- When adding a tool via Homebrew: Add to `installation/Brewfile`
- When creating files that need symlinking to home directory: Use `*.symlink` naming convention (handled automatically by installation script)

**Why this matters**:

- Installation script enables easy setup on new computers
- Documentation prevents losing track of what's been implemented
- Both are essential for the dotfiles to be usable and maintainable

Update documentation and installation files IMMEDIATELY after implementing features, not later.

### 4. NEVER Commit Without User Approval

**CRITICAL**: Do NOT create commits unless explicitly told to by the user.

- After making changes, STOP and let the user review
- Only run `git commit` when user says "commit" or similar
- User wants the opportunity to test and verify changes first
- If user asks "can you commit?", that means ask for permission, NOT commit immediately

**Bad**: Making changes → Immediately running `git commit`
**Good**: Making changes → Telling user "Changes are ready, let me know when you want to commit"

**Commit messages** should be clean and focused on the work:

- Write concise, descriptive commit messages
- DO NOT include trailing footers like "Generated with Claude Code" or "Co-Authored-By" trailers
- These footers add unnecessary noise to git history
- Keep commit messages focused on the "what" and "why" of the change

### 5. Consider Error Handling and Edge Cases

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
