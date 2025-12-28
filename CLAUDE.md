# Dotfiles Project Rules

## Project Overview

Migrating and modernizing dotfiles from old implementation:
- **Source**: @https://github.com/davidsu/dotfiles/tree/dotfilesold (Vimscript, vim-plug, ag, fnm)
- **Target**: `~/.dotfiles/` (Pure Lua, lazy.nvim, ripgrep, mise)
- **Platform**: macOS only (remove all Linux compatibility code)
- **Goal**: Keep functionality, modernize implementation, clean up cruft

## Critical Rules

### 1. Don't Rush to Implementation
When user asks a question, **answer the question** - don't implement anything unless explicitly asked.

**Bad**: User asks "what colorscheme did I use?" → You immediately add a colorscheme plugin
**Good**: User asks "what colorscheme did I use?" → You check dotfilesold and tell them

### 2. Check Dotfilesold First
Before implementing ANY feature, check how it was done in the old dotfiles at @https://github.com/davidsu/dotfiles/tree/dotfilesold

Don't assume or guess - look at the actual old code.

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

### 5. Keep Documentation Updated
All `.md` files must remain up to date:
- **Project root**: `~/.dotfiles/*.md` (README.md, tasks.md, planning.md, etc.)
- **Neovim docs**: `~/.dotfiles/config.home.symlink/nvim/*.md`

When implementing features, update relevant documentation immediately.
