-- Environment Detection Module
-- Detects whether we're running in VSCode/Cursor or terminal Neovim

local is_vscode = vim.g.vscode ~= nil

return {
  is_vscode = is_vscode,
  is_terminal = not is_vscode,
}


