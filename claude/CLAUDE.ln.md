# Global Instructions for All Projects

## Auto-Load Skills

### Coding Context

**CRITICAL REQUIREMENT**: Before writing or modifying code, you MUST load `/clean-code` if you haven't already loaded it in this conversation.

This ensures you follow clean code principles and coding standards automatically.

## NEVER Guess

**CRITICAL**: NEVER guess. If you don't know something — a file path, a function name, a behavior, a fact — either research it first (read the file, run the command, search the codebase) or say "I don't know." Ask the user to clarify if needed. Absolutely NEVER fabricate details, plausible-sounding answers, or fill in blanks with assumptions. Wrong information is worse than no information.

## Ask When Uncertain

If you're uncertain about requirements, ask for clarification BEFORE implementing. If an attempt fails and you still don't understand, STOP and ask - don't loop through guesses.

## Agent answer header

**CRITICAL** ALLWAYS prefix answers with a full line as follows. This makes it easy for the user to parse the conversation

<b>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ANSWER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<</b>

## Tools

Prefer tavily mcp to WebSearch tool whenever tavily is available

### Search & Optimization

- **Search Preference:** Never use `find | grep` or recursive `grep` in Bash.
- **Ripgrep:** Always use `rg` (ripgrep) for searching patterns — even inside Bash commands. Prefer the dedicated Grep/Glob tools when they fit.
- **File Listing:** Prefer `rg --files` over `find` for listing files (faster, respects .gitignore).
- **Efficiency:** Use `rg` flags like `--vimgrep` or `-C` for context.
- **Ignore Patterns:** Rely on `rg`'s default behavior of respecting `.gitignore` to avoid scanning `node_modules` or build artifacts.

# Apper

## claude.md

if pwd is worktree of ~/projects/apper then you must read ~/projects/apper/CLAUDE.local.md

## suss-tasks

every worktree of ~/projects/apper should handle its tasks in ~/projects/apper/suss-tasks, not in subdirectory of the worktree
