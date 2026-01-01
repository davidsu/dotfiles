-- Treesitter Configuration
-- Provides advanced syntax highlighting and code understanding

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,  -- This plugin does not support lazy-loading
    config = function()
      -- Automatically install parsers for commonly used languages
      require('nvim-treesitter').install {
        'tsx',
        'typescript',
        'javascript',
        'lua',
        'markdown',
        'markdown_inline',
        'json',
        'html',
        'css',
      }

      -- Enable treesitter highlighting for supported filetypes (if parser is available)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'typescript',
          'typescriptreact',
          'javascript',
          'javascriptreact',
          'lua',
          'markdown',
          'json',
          'html',
          'css',
        },
        callback = function()
          -- Only start treesitter if parser is available
          local ok = pcall(vim.treesitter.start)
          if not ok then
            -- Parser not installed, silently fall back to default syntax
            return
          end
        end,
      })

      -- Enable treesitter-based indentation (experimental)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'typescript',
          'typescriptreact',
          'javascript',
          'javascriptreact',
          'lua',
        },
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
