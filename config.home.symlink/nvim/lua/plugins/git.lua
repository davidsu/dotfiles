-- Git Integration Plugins
-- Loaded only in terminal (VSCode/Cursor has built-in git)

local env = require('core.env')

if env.is_vscode then
  return {}
end

return {
  -- Git wrapper
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'Gread', 'Gwrite', 'Gdiffsplit', 'Gvdiffsplit' },
    keys = {
      { '<space>gs', '<cmd>Git<cr>', desc = 'Git status' },
      { '<space>gd', '<cmd>Gdiffsplit<cr>', desc = 'Git diff' },
      { 'gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
    },
  },

  -- GitHub integration for fugitive
  {
    'tpope/vim-rhubarb',
    dependencies = { 'tpope/vim-fugitive' },
  },

  -- Git signs in gutter
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']g', function()
            if vim.wo.diff then return ']g' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = 'Next git hunk' })

          map('n', '[g', function()
            if vim.wo.diff then return '[g' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = 'Previous git hunk' })

          -- Actions
          map('n', '<space>hs', gs.stage_hunk, { desc = 'Stage hunk' })
          map('n', '<space>hr', gs.reset_hunk, { desc = 'Reset hunk' })
          map('n', '<space>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
          map('n', '<space>hp', gs.preview_hunk, { desc = 'Preview hunk' })
        end,
      })
    end,
  },
}


