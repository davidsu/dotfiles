---
name: coding:neovim
description: Development workflow for Neovim Lua code. Always load when writing or modifying Lua code that runs in Neovim, including tests.
---

# Neovim Lua Development Workflow

Follow this workflow when implementing or modifying Lua code that runs in Neovim.

## The Loop: Implement, Verify, Test

Every change follows this cycle:

### 1. Implement

Write the code change in the plugin file.

### 2. Manual test via MCP

Verify the change works in the running Neovim instance using MCP tools:

1. **Reload the module**: Clear the cached module and re-run setup:
   ```lua
   vim_command: lua package.loaded["<module>"] = nil; vim.loader.reset(); require("<module>").setup()
   ```
2. **Exercise the feature**: Use `vim_command`, `vim_buffer`, `vim_edit`, `vim_search` etc. to interact with the plugin and verify behavior.
3. **Check the result**: Read buffer contents with `vim_buffer` to confirm expected output.

**MCP tips:**
- `vim_buffer` shows the current window's buffer — switch to the right window first
- Use `vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Key>", true, false, true), "x", false)` for special keys
- After module reload + `setup()`, close and reopen any plugin windows so keymaps bind to the new buffer
- For Tab key: `vim.api.nvim_replace_termcodes("<Tab>", true, false, true)`

### 3. Self-heal / repeat

If the manual test fails:
- Read error messages carefully
- Fix the code
- Re-run the manual test
- **Do not proceed to writing tests until the feature works manually**

### 4. Write Plenary tests

Once the feature works manually, write tests in the `*_spec.lua` file using Plenary busted syntax.

### 5. Run tests in Neovim

Run tests inside the MCP Neovim instance:
```
vim_command: PlenaryBustedFile /path/to/spec_file.lua
```

Then wait for results and read the output buffer with `vim_buffer`.

**Tests are slow** (each `before_each` creates a git repo + beads). Wait adequately before checking results — typically 2+ minutes for the full suite.

### 6. Self-heal / repeat

If tests fail:
- Read the failure output
- Fix the code or test
- Re-run `PlenaryBustedFile`
- Repeat until green

## MCP Connection Required

**CRITICAL**: Before starting manual testing or running Plenary tests, check that the Neovim MCP connection is healthy using `vim_health`.

If MCP tools are unavailable or return errors: **STOP immediately**. Do not attempt workarounds (headless nvim, Bash-based testing, skipping manual verification). Ask the user to provide a healthy Neovim MCP connection before continuing.

The MCP connection is not optional — it is the core of this workflow.

## Key Principles

- **Manual first**: Never write tests for code you haven't verified manually. The MCP connection to Neovim is your REPL.
- **One thing at a time**: Implement one feature, verify it, then move to the next.
- **Real environment**: Manual testing catches issues that unit tests miss (window management, keymaps, buffer lifecycle).
