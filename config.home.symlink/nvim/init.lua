-- Neovim Configuration
-- Pure Lua configuration for Neovim

-- Set leader keys BEFORE loading lazy.nvim
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- 1. Detect environment first
local env = require('core.env')

-- 2. Core settings (all environments)
require('core.options')

-- 3. Bootstrap lazy.nvim (only if not in VSCode/Cursor)
if not env.is_vscode then
  require('core.lazy')
end

-- 4. Core keymaps (all environments)
require('core.keymaps')
