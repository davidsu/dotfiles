# Global Instructions for All Projects

## Tool Usage & Optimization
- **File Listing:** Prefer `rg --files` over `find` for listing files (faster, respects .gitignore)
- **Search Preference:** Never use `find | grep` or recursive `grep`.
- **Ripgrep:** Always use `rg` (ripgrep) for searching patterns.
- **Efficiency:** Use `rg` flags like `--vimgrep` or `-C` for context.
- **Ignore Patterns:** Rely on `rg`'s default behavior of respecting `.gitignore` to avoid scanning `node_modules` or build artifacts.

## Auto-Load Skills

### Coding Context

**CRITICAL REQUIREMENT**: Before writing or modifying code, you MUST load `/cleanCode` if you haven't already loaded it in this conversation.

This ensures you follow clean code principles and coding standards automatically.
