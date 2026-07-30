-- Treesitter Configuration
-- Provides advanced syntax highlighting and code understanding
local function config()
  require('nvim-treesitter.configs').setup({
    -- Ensure installed parsers for commonly used languages
    ensure_installed = {
      'tsx',
      'typescript',
      'javascript',
      'lua',
      'markdown',
      'markdown_inline',
      'json',
      'html',
      'css',
      'python',
    },

    -- Enable highlighting
    highlight = {
      enable = true,
    },

    -- Enable indentation
    indent = {
      enable = true,
    },
  })
end

local selection_keys = {
  ['af'] = '@function.outer',
  ['if'] = '@function.inner',
  ['ac'] = '@class.outer',
  ['ic'] = '@class.inner',
  ['ai'] = '@conditional.outer',
  ['ii'] = '@conditional.inner',
  ['al'] = '@loop.outer',
  ['il'] = '@loop.inner',
  ['aa'] = '@parameter.outer',
  ['ia'] = '@parameter.inner',
}

-- '[f'/']f' are deliberately absent: vim-unimpaired owns them for file navigation
local movement_keys = {
  goto_next_start = {
    [']]'] = '@function.outer',
    [']m'] = '@class.outer',
  },
  goto_next_end = {
    [']['] = '@function.outer',
  },
  goto_previous_start = {
    ['[['] = '@function.outer',
    ['[m'] = '@class.outer',
  },
  goto_previous_end = {
    ['[]'] = '@function.outer',
  },
}

local function map_selection_keys()
  for key, query in pairs(selection_keys) do
    vim.keymap.set({ 'x', 'o' }, key, function()
      require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
    end, { silent = true, desc = 'Select ' .. query })
  end
end

local function map_movement_keys()
  for movement, keys in pairs(movement_keys) do
    for key, query in pairs(keys) do
      vim.keymap.set({ 'n', 'x', 'o' }, key, function()
        require('nvim-treesitter-textobjects.move')[movement](query, 'textobjects')
      end, { silent = true, desc = movement .. ' ' .. query })
    end
  end
end

local function config_textobjects()
  require('nvim-treesitter-textobjects').setup({
    select = { lookahead = true },
    move = { set_jumps = true },
  })
  map_selection_keys()
  map_movement_keys()
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    lazy = false,      -- This plugin does not support lazy-loading
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = config,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    config = config_textobjects,
  },
}
