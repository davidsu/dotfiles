-- Markdown Preview
-- Browser-based markdown preview with live updates (pure Lua, no dependencies)

return {
  {
    'brianhuster/live-preview.nvim',
    ft = { 'markdown', 'html' },  -- Load for markdown and HTML files
    config = function()
      require('livepreview').setup({
        -- Port for preview server (0 = auto)
        port = 5500,
        
        -- Auto-open browser when starting preview
        autokill = true,  -- Kill server when Neovim exits
      })
      
      -- Keybindings for markdown/html buffers
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'html' },
        callback = function()
          local opts = { buffer = true, silent = true }
          vim.keymap.set('n', '<leader>mp', '<cmd>LivePreview<cr>', opts)
          vim.keymap.set('n', '<leader>ms', '<cmd>StopPreview<cr>', opts)
        end,
      })
    end,
  },
}

