-- Folding with nvim-ufo

-- Chain: lsp -> treesitter -> indent
-- Falls back gracefully if LSP doesn't support folding for the filetype
local function lsp_treesitter_indent_chain(bufnr)
  local function handleFallbackException(err, providerName)
    if type(err) == 'string' and err:match('UfoFallbackException') then
      return require('ufo').getFolds(bufnr, providerName)
    else
      return require('promise').reject(err)
    end
  end

  return require('ufo').getFolds(bufnr, 'lsp'):catch(function(err)
    return handleFallbackException(err, 'treesitter')
  end):catch(function(err)
    return handleFallbackException(err, 'indent')
  end)
end

-- Select which fold provider to use based on filetype
local function select_fold_provider(_bufnr, filetype, _buftype)
  -- Disable ufo for quickfix (causes errors when window closes)
  if filetype == 'qf' then
    return ''
  end
  if filetype == 'markdown' then
    return { 'treesitter', 'indent' }
  end
  return lsp_treesitter_indent_chain
end

-- Remap zM and zR to use ufo's functions instead of native vim commands
-- This keeps foldlevel high, preventing auto-closing folds when buffer is modified
local function setup_keymaps()
  vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
  vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
  vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = 'Open folds incrementally' })
  vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = 'Close folds incrementally' })
end

-- Enable folding for man pages (man filetype disables it by default)
local function setup_man_folding()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'man',
    callback = function()
      vim.opt_local.foldenable = true
    end,
  })
end

local function config()
  require('ufo').setup({
    open_fold_hl_timeout = 0,
    provider_selector = select_fold_provider,
  })

  setup_keymaps()
  setup_man_folding()
end

return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'VeryLazy',
    init = function()
      -- Set early so they're in effect before ufo loads.
      -- foldlevelstart is ignored for foldmethod=manual (which ufo sets),
      -- so we also force foldlevel=99 on every new window via autocmd.
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.api.nvim_create_autocmd('BufWinEnter', {
        callback = function()
          vim.wo.foldlevel = 99
        end,
      })
    end,
    config = config,
  },
}
