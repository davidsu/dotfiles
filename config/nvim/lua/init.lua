local utils = require 'utils'
local isModuleAvailable = utils.isModuleAvailable
local hasPacker = utils.hasPacker
if not hasPacker() then
  require('plugins')
else
  require('plugins')
end
vim.api.nvim_exec([[
augroup packer_compile
  au!
  autocmd BufWritePost plugins.lua luafile %
  autocmd BufWritePost plugins.lua PackerCompile
augroup END
]], {})

require('spaceline')
require('lsp_configuration')
if isModuleAvailable('nvim-treesitter.configs') then
  require'nvim-treesitter.configs'.setup {
    ensure_installed = { "typescript" },
    highlight = { 
      enable = true,
      disable = {'json', 'jsonc'}
    }, 
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "+",
        scope_incremental = "-",
        node_decremental = "_",
      },
    },
  }
end
-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- vim.wo.foldmethod = 'expr'
-- vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'

if isModuleAvailable('colorizer') then
  require'colorizer'.setup()
end
