-- UI Enhancements
-- Loaded only in terminal (not needed in VSCode/Cursor)

local env = require('core.env')

if env.is_vscode then
  return {}
end

local function ufo_config()
  vim.o.foldcolumn = '0'
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true

  require('ufo').setup({
    open_fold_hl_timeout = 0, -- disable highlight flash when opening folds
    provider_selector = function(bufnr, filetype, buftype)
      -- Disable folding for certain filetypes
      local ignore_filetypes = { 'fzf', 'TelescopePrompt', 'nofile' }
      for _, ft in ipairs(ignore_filetypes) do
        if filetype == ft or buftype == ft then
          return ''
        end
      end
      return { 'lsp', 'treesitter' }
    end,
  })

  -- Remap zM and zR to use ufo's functions instead of native vim commands
  -- This keeps foldlevel high, preventing auto-closing folds when buffer is modified
  vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
  vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
  vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = 'Open folds incrementally' })
  vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = 'Close folds incrementally' })
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
