local utils = require 'utils'
local isModuleAvailable = utils.isModuleAvailable
local hasPacker = utils.hasPacker
if not hasPacker() then
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

if isModuleAvailable('nvim-treesitter.configs') then
require'nvim-treesitter.configs'.setup {
  highlight = { enable = true }, 
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
if isModuleAvailable('colorizer') then
  require'colorizer'.setup()
end
