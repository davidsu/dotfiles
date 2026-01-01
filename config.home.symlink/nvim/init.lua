-- Neovim Configuration
-- Pure Lua configuration for Neovim

-- Set leader keys BEFORE loading lazy.nvim
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- 1. Detect environment first
local env = require('core.env')

-- 2. Core settings (all environments)
require('core.options')

-- 3. Bootstrap lazy.nvim (all environments)
require('core.lazy')

-- 4. Core keymaps (all environments)
require('core.keymaps')

-- 5. Core commands (all environments)
require('core.commands')

-- 6. MRU tracking (terminal only)
if env.is_terminal then
  require('config.mru').setup()
end
