-- Folding with nvim-ufo

local env = require('core.env')

if env.is_vscode then
  return {}
end

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

-- Filetype-specific fold providers
local function get_markdown_fold_provider(filetype)
  if filetype == 'markdown' then
    return { 'treesitter', 'indent' }
  end
end

-- Select which fold provider to use based on filetype
local function select_fold_provider(_bufnr, filetype, _buftype)
  return get_markdown_fold_provider(filetype) or lsp_treesitter_indent_chain
end

-- Remap zM and zR to use ufo's functions instead of native vim commands
-- This keeps foldlevel high, preventing auto-closing folds when buffer is modified
local function setup_keymaps()
  vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
  vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
  vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = 'Open folds incrementally' })
  vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = 'Close folds incrementally' })
end

-- Reload nvim-ufo if markdown fold manager is stuck in pending state
local function reload_ufo_if_pending(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local fb = require('ufo.fold.manager'):get(bufnr)
  if fb and fb.status == 'pending' then
    -- Suppress the "Reloading" notification
    local original_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function() end

    require('lazy.core.loader').reload('nvim-ufo')

    vim.notify = original_notify
  end
end

-- Callback for markdown BufEnter: reload ufo after 350ms if needed
local function on_markdown_buf_enter()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.defer_fn(function()
    reload_ufo_if_pending(bufnr)
  end, 350)
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

-- Workaround for markdown files not folding on initial load
local function setup_markdown_workaround()
  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*.md',
    callback = on_markdown_buf_enter,
  })
end

local function config()
  vim.o.foldcolumn = '0'
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true

  require('ufo').setup({
    open_fold_hl_timeout = 0,
    provider_selector = select_fold_provider,
  })

  setup_keymaps()
  setup_man_folding()
  setup_markdown_workaround()
end

return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'VeryLazy',
    config = config,
  },
}
