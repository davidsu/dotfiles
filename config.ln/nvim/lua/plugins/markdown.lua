-- Markdown Preview
-- Browser-based markdown preview with live updates

return {
  -- DISABLED: live-preview.nvim has file descriptor leaks
  -- Causes "Too many open files" error with extensive use
  -- See: ~/.claude/plans/squishy-percolating-owl.md
  -- {
  --   'brianhuster/live-preview.nvim',
  --   ft = { 'markdown', 'html' },
  --   config = function()
  --     require('livepreview').setup({
  --       port = 5500,
  --       autokill = true,
  --     })
  --
  --     vim.api.nvim_create_autocmd('FileType', {
  --       pattern = { 'markdown', 'html' },
  --       callback = function()
  --         local opts = { buffer = true, silent = true }
  --         vim.keymap.set('n', '<leader>mp', '<cmd>LivePreview<cr>', opts)
  --         vim.keymap.set('n', '<leader>ms', '<cmd>StopPreview<cr>', opts)
  --       end,
  --     })
  --   end,
  -- },

  -- Markdown preview with Node.js (no file descriptor leaks)
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
  },
}

