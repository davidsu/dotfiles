-- Core Autocmds
-- Autocmd definitions (separated from keymaps and options for clarity)

-- Auto-reload buffer if file changed externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = '*',
  callback = function()
    vim.cmd('checktime')
  end,
})

-- Configure folding for specific filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'tsx', 'jsx', 'lua' },
  callback = function()
    -- Use custom fold expression that includes comments
    local folding = require('utils.folding')
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'v:lua.require("utils.folding").foldexpr_with_comments()'
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevelstart = 99
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

-- Close help/quickfix/fugitive buffers with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'fugitiveblame' },
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true, silent = true })
  end,
})

