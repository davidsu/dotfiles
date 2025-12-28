-- Treesitter Configuration
-- Provides advanced syntax highlighting and code understanding

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,  -- Load immediately instead of on event
    config = function()
      -- Only configure if treesitter is actually available
      local ok, treesitter = pcall(require, 'nvim-treesitter.configs')
      if not ok then
        return
      end

      treesitter.setup({
        -- Install parsers for these languages
        ensure_installed = {
          'bash',
          'css',
          'html',
          'javascript',
          'json',
          'lua',
          'markdown',
          'markdown_inline',
          'python',
          'regex',
          'tsx',
          'typescript',
          'vim',
          'yaml',
        },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        auto_install = true,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          -- Disable overly strict markdown error highlighting
          disable = function(lang, buf)
            if lang == "markdown" then
              -- Check if we should disable highlighting for errors
              return false
            end
            return false
          end,
        },

        indent = {
          enable = true,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<S-CR>',
            node_decremental = '<BS>',
          },
        },
      })
    end,
  },
}
