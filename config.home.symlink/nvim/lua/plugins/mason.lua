-- Mason Configuration
-- Automatic installation and management of LSP servers, formatters, and linters

local function setup_mason()
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
end

local function setup_mason_lspconfig()
  require('mason-lspconfig').setup({
    ensure_installed = {
      'ts_ls',
      'eslint',
      'lua_ls',
      'bashls',
    },
    automatic_installation = true,
  })
end

local function setup_mason_tool_installer()
  require('mason-tool-installer').setup({
    ensure_installed = {
      'prettier',
    },
    auto_update = false,
    run_on_start = true,
  })
end

return {
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    build = ':MasonUpdate',
    config = setup_mason,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = setup_mason_lspconfig,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = setup_mason_tool_installer,
  },
}
