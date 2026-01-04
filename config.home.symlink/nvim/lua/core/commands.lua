-- Core User Commands
-- User-defined commands (not keymaps)


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

-- Toggle signs (sign column, gitsigns, diagnostics)
local signs_enabled = false
vim.api.nvim_create_user_command('Signs', function()
  signs_enabled = not signs_enabled
  vim.opt.signcolumn = signs_enabled and 'yes' or 'no'

  -- Toggle gitsigns if available
  local gs_ok, gitsigns = pcall(require, 'gitsigns')
  if gs_ok then
    gitsigns.toggle_signs(signs_enabled)
  end

  -- Toggle diagnostic signs
  vim.diagnostic.config({ signs = signs_enabled })

  vim.notify('Signs ' .. (signs_enabled and 'enabled' or 'disabled'))
end, { desc = 'Toggle sign column and all signs' })

