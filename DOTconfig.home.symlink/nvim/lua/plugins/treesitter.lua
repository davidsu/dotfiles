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

    -- Configure textobjects
    textobjects = {
      select = {
        enable = true,
        lookahead = true,     -- Automatically jump forward to textobj
        keymaps = {
          -- Functions
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          -- Classes
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
          -- Conditionals
          ['ai'] = '@conditional.outer',
          ['ii'] = '@conditional.inner',
          -- Loops
          ['al'] = '@loop.outer',
          ['il'] = '@loop.inner',
          -- Parameters/arguments
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
        },
      },
    },
  })
end
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- Use stable master branch for compatibility with textobjects
    build = ':TSUpdate',
    lazy = false,      -- This plugin does not support lazy-loading
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = config,
  },
}
