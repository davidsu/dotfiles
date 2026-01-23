-- Core Autocmds
-- Autocmd definitions (separated from keymaps and options for clarity)

-- Helper: Map 'q' to close buffer in special windows
local function map_q_to_close_buffer()
  vim.keymap.set('n', 'q', '<cmd>bdelete<cr>', { buffer = true, silent = true })
end

-- Highlight yanked text briefly for visual feedback
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({ timeout = 40 })
  end,
})

-- Auto-reload buffer if file changed externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = '*',
  callback = function()
    vim.cmd('checktime')
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
    end, 100) -- 100ms delay to let other instance finish wshada
  end,
})

-- This tells Neovim to use the built-in filetype indent instead of Treesitter's
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact" },
  callback = function()
    vim.opt_local.indentexpr = "GetTypescriptIndent()"
  end,
})

-- Close help/quickfix/location list/fugitive buffers with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'fugitiveblame', 'fugitive' },
  callback = map_q_to_close_buffer,
})

-- Close preview windows with q
vim.api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if vim.wo.previewwindow then
      map_q_to_close_buffer()
    end
  end,
})
