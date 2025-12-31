-- Completion Configuration
-- nvim-cmp for autocompletion with LSP integration

return {
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',     -- LSP completion source
      'hrsh7th/cmp-buffer',        -- Buffer completion source
      'hrsh7th/cmp-path',          -- Path completion source
    },
    config = function()
      local cmp = require('cmp')

      cmp.setup({
        completion = {
          autocomplete = { require('cmp.types').cmp.TriggerEvent.TextChanged },
          completeopt = 'menu,menuone,noinsert',
        },

        mapping = cmp.mapping.preset.insert({
          -- Navigate completion menu
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll documentation
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Accept completion
          ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Only confirm explicitly selected items
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),  -- Tab accepts current/first item

          -- Close completion menu without exiting insert mode
          ['<C-e>'] = cmp.mapping.abort(),

          -- Manually trigger completion
          ['<C-Space>'] = cmp.mapping.complete(),
        }),

        sources = cmp.config.sources({
          { name = 'nvim_lsp' },  -- LSP completions (highest priority)
          { name = 'path' },      -- File path completions
        }, {
          { name = 'buffer', keyword_length = 3 }, -- Buffer completions (only after 3 chars)
        }),

        -- Formatting of completion menu
        formatting = {
          format = function(entry, vim_item)
            -- Show source in completion menu
            vim_item.menu = ({
              nvim_lsp = '[LSP]',
              buffer = '[Buf]',
              path = '[Path]',
            })[entry.source.name]
            return vim_item
          end,
        },

        -- Experimental ghost text (shows completion as grey text)
        experimental = {
          ghost_text = false, -- Set to true if you want inline ghost text
        },
      })
    end,
  },
}
