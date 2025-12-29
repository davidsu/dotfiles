-- Environment Detection Module
-- Detects whether we're running in VSCode/Cursor or terminal Neovim

local M = {}

-- VSCode/Cursor both set vim.g.vscode
M.is_vscode = vim.g.vscode ~= nil

-- Terminal is any environment that's not VSCode/Cursor
M.is_terminal = not M.is_vscode

return M


