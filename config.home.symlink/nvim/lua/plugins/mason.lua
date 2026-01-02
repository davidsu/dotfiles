-- Mason Configuration
-- Automatic installation and management of LSP servers, formatters, and linters

return {
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    build = ':MasonUpdate',
    config = function()
      require('mason').setup({
        ui = {
          border = 'rounded',
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      })
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        -- Automatically install these language servers
        ensure_installed = {
          'ts_ls',    -- TypeScript/JavaScript
          'eslint',   -- ESLint
          'lua_ls',   -- Lua
          'bashls',   -- Bash/Zsh
        },
        -- Automatically install any server configured via lspconfig
        automatic_installation = true,
      })
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-tool-installer').setup({
        -- Automatically install formatters and linters
        ensure_installed = {
          'prettier',  -- JavaScript/TypeScript formatter
        },
        -- Auto-update on startup
        auto_update = false,
        -- Install if missing
        run_on_start = true,
      })
    end,
  },
}
