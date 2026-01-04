-- UI Enhancements
-- Loaded only in terminal (not needed in VSCode/Cursor)

local env = require('core.env')

if env.is_vscode then
  return {}
end

local function ufo_config()
  vim.o.foldcolumn = '1'
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true

  require('ufo').setup({
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
  })
end

return {
  -- Smooth scrolling
  {
    'psliwka/vim-smoothie',
    event = 'VeryLazy',
  },

  -- Dim inactive windows
  {
    'blueyed/vim-diminactive',
    event = 'VeryLazy',
    config = function()
      vim.g.diminactive_enable_focus = 1
    end,
  },

  -- Better folding with VSCode-like fold UI
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'VeryLazy',
    config = ufo_config,
  },
}


