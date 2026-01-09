-- Folding with nvim-ufo

local env = require('core.env')

if env.is_vscode then
  return {}
end

local function config()
  vim.o.foldcolumn = '0'
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true

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

  require('ufo').setup({
    open_fold_hl_timeout = 0, -- disable highlight flash when opening folds
    provider_selector = function(bufnr, filetype, buftype)
      if filetype == 'markdown' then
        return { 'treesitter', 'indent' }
      end
      return lsp_treesitter_indent_chain
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
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'VeryLazy',
    config = config,
  },
}
