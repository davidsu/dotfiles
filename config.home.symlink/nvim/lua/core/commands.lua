-- Core User Commands
-- User-defined commands (not keymaps)

vim.api.nvim_create_user_command('Diagnostics', function()
  vim.diagnostic.setqflist()
end, { desc = 'Show all diagnostics in quickfix list' })

-- Copy to system clipboard helper
local function to_clipboard(value)
  vim.fn.setreg('+', value)
  vim.notify('Copied: ' .. value)
end

vim.api.nvim_create_user_command('CopyFilePath', function()
  to_clipboard(vim.fn.expand('%:p'))
end, { desc = 'Copy full file path to clipboard' })

vim.api.nvim_create_user_command('CopyFileName', function()
  to_clipboard(vim.fn.expand('%:t'))
end, { desc = 'Copy file name to clipboard' })

vim.api.nvim_create_user_command('CopyFileNameNoExtension', function()
  to_clipboard(vim.fn.expand('%:t:r'))
end, { desc = 'Copy file name without extension to clipboard' })

vim.api.nvim_create_user_command('CopyRelativeFilePath', function()
  to_clipboard(vim.fn.expand('%:.'))
end, { desc = 'Copy relative file path to clipboard' })

