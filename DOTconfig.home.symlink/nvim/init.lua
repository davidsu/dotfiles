-- Neovim Configuration

-- Set leader keys BEFORE loading lazy.nvim
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('core.options')
require('core.lazy')
require('core.autocmds')
require('core.keymaps')
require('core.commands')
require('config.mru').setup()
require('config.claude').setup()
require('utils.commit-diff')
