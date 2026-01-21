# Global Instructions for All Projects

## Tool Usage & Optimization
- **File Listing:** Prefer `rg --files` over `find` for listing files (faster, respects .gitignore)
- **Search Preference:** Never use `find | grep` or recursive `grep`.
- **Ripgrep:** Always use `rg` (ripgrep) for searching patterns.
- **Efficiency:** Use `rg` flags like `--vimgrep` or `-C` for context.
- **Ignore Patterns:** Rely on `rg`'s default behavior of respecting `.gitignore` to avoid scanning `node_modules` or build artifacts.

## Auto-Load Skills

### Coding Context

**IMPORTANT**: Before writing, editing, or refactoring code, you MUST read the coding skill if you haven't already read it in this conversation:

- Run: `/coding` to load coding style guidelines

This ensures you follow the project's coding standards automatically.
