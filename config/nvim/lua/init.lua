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
  -- annoying: need to defer setting config of treesitter otherwise syntax highlight fails for first buffer
  vim.defer_fn(function()
    require'nvim-treesitter.configs'.setup {
      ensure_installed = { "javascript", "typescript", "lua", "vim", "python" },
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
    local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
    parser_config.dockerfile = {
      install_info = {
        url = "https://github.com/camdencheek/tree-sitter-dockerfile", -- local path or git repo
        files = {"src/parser.c"},
        -- optional entries:
        branch = "main", -- default branch in case of git repo if different from master
        generate_requires_npm = false, -- if stand-alone parser without npm dependencies
        requires_generate_from_grammar = true, -- if folder contains pre-generated src/parser.c
      },
      filetype = "dockerfile", -- if filetype does not match the parser name
    }
  end, 10)
end
-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- vim.wo.foldmethod = 'expr'
-- vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'

if isModuleAvailable('colorizer') then
  require'colorizer'.setup()
end
