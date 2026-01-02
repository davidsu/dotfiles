-- Core User Commands
-- User-defined commands (not keymaps)

vim.api.nvim_create_user_command('Diagnostics', function()
  vim.diagnostic.setqflist()
end, { desc = 'Show all diagnostics in quickfix list' })

