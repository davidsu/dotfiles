-- Completion Configuration
-- nvim-cmp for autocompletion with LSP integration

local function get_mappings(cmp)
  return cmp.mapping.preset.insert({
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
  })
end

local function get_sources(cmp)
  return cmp.config.sources({
    { name = 'nvim_lsp' }, -- LSP completions (highest priority)
    { name = 'path' },     -- File path completions
  }, {
    { name = 'buffer', keyword_length = 3 }, -- Buffer completions (only after 3 chars)
  })
end

local function get_format(entry, vim_item)
  -- Show source in completion menu
  vim_item.menu = ({
    nvim_lsp = '[LSP]',
    buffer = '[Buf]',
    path = '[Path]',
  })[entry.source.name]
  return vim_item
end

local function config()
  local cmp = require('cmp')

  cmp.setup({
    completion = {
      autocomplete = { require('cmp.types').cmp.TriggerEvent.TextChanged },
      completeopt = 'menu,menuone,noinsert',
    },
    mapping = get_mappings(cmp),
    sources = get_sources(cmp),
    formatting = { format = get_format },
    experimental = { ghost_text = false },
  })
end

return {
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp', -- LSP completion source
      'hrsh7th/cmp-buffer',   -- Buffer completion source
      'hrsh7th/cmp-path',     -- Path completion source
    },
    config = config,
  },
}
