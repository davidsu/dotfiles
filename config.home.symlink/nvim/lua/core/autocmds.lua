-- Core Autocmds
-- Autocmd definitions (separated from keymaps and options for clarity)

-- Auto-reload buffer if file changed externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = '*',
  callback = function()
    vim.cmd('checktime')
  end,
})

-- Markdown uses manual folding (for preview compatibility)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  callback = function()
    vim.opt_local.foldmethod = 'manual'
    vim.opt_local.foldenable = false
  end,
})

-- Auto-save: write all modified buffers when focus is lost or switching windows
vim.api.nvim_create_autocmd({ 'FocusLost', 'WinLeave' }, {
  pattern = '*',
  callback = function()
    vim.cmd('silent! wa')
  end,
})

-- Sync command-line history across instances
vim.api.nvim_create_autocmd('FocusLost', {
  callback = function()
    vim.cmd('wshada')
  end,
})

vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    vim.defer_fn(function()
      vim.cmd('rshada!')
    end, 100)  -- 100ms delay to let other instance finish wshada
  end,
})

-- Close help/quickfix/fugitive buffers with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'fugitiveblame' },
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true, silent = true })
  end,
})

