-- Core User Commands
-- User-defined commands (not keymaps)

local comment_folds_visible = true
vim.api.nvim_create_user_command('FoldCommentsToggle', function()
  local folding = require('utils.folding')
  if comment_folds_visible then
    folding.fold_comments_only()
    comment_folds_visible = false
  else
    folding.unfold_comments_only()
    comment_folds_visible = true
  end
end, { desc = 'Toggle fold state of comment blocks' })

vim.api.nvim_create_user_command('Diagnostics', function()
  vim.diagnostic.setqflist()
end, { desc = 'Show all diagnostics in quickfix list' })

