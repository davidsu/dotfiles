-- LSP Configuration
-- Native Neovim Language Server Protocol support

local diagnostic_config = {
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✖',
      [vim.diagnostic.severity.WARN] = '⚠',
      [vim.diagnostic.severity.HINT] = '💡',
      [vim.diagnostic.severity.INFO] = 'ℹ',
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
}

local function setup_diagnostics()
  vim.diagnostic.config(diagnostic_config)
  vim.api.nvim_create_autocmd('CursorHold', {
    callback = require('utils.diagnostics').show_diagnostic_at_cursor,
  })
end

local function close_floating_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= '' then
      vim.api.nvim_win_close(win, false)
    end
  end
end

local function jump_to_prev_diagnostic()
  vim.diagnostic.jump({ count = -1, float = { border = 'rounded' } })
end

local function jump_to_next_diagnostic()
  vim.diagnostic.jump({ count = 1, float = { border = 'rounded' } })
end

local function setup_lsp_folding(client)
  if client:supports_method('textDocument/foldingRange') then
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevelstart = 99
  end
end

local function on_lsp_attach(args)
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if not client then
    return
  end

  local bufnr = args.buf
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set('n', '<space>cd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set({ 'n', 'x' }, '<space>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<space>cf', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<space>lo', vim.diagnostic.setloclist, opts)
  vim.keymap.set('n', '[d', jump_to_prev_diagnostic, opts)
  vim.keymap.set('n', ']d', jump_to_next_diagnostic, opts)

  if client:supports_method('textDocument/formatting') then
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format({ async = true })
    end, opts)
  end

  vim.keymap.set('n', '<C-c>', close_floating_windows, opts)
  vim.keymap.set('n', '<Esc>', close_floating_windows, opts)

  setup_lsp_folding(client)
end

local function setup_lsp_keybindings()
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = on_lsp_attach,
  })
end

local typescript_settings = {
  typescript = {
    suggest = {
      includeCompletionsForImportStatements = true,
    },
    preferences = {
      importModuleSpecifier = 'relative',
    },
  },
  javascript = {
    suggestionActions = {
      enabled = true,
    },
  },
}

local eslint_settings = {
  format = false,
  run = 'onType',
}

local lua_settings = {
  Lua = {
    runtime = {
      version = 'LuaJIT',
    },
    diagnostics = {
      globals = { 'vim', 'hs' },
    },
    workspace = {
      library = {
        vim.fn.expand('$VIMRUNTIME/lua'),
        vim.fn.stdpath('config') .. '/lua',
      },
      checkThirdParty = false,
    },
    telemetry = {
      enable = false,
    },
  },
}

local bashls_filetypes = { 'sh', 'bash', 'zsh' }

local function setup_lsp(server_name, config)
  vim.lsp.config(server_name, config)
  vim.lsp.enable(server_name)
end

local function config()
  setup_diagnostics()
  setup_lsp_keybindings()

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  setup_lsp('ts_ls', { capabilities = capabilities, settings = typescript_settings })
  setup_lsp('eslint', { capabilities = capabilities, settings = eslint_settings })
  setup_lsp('lua_ls', { capabilities = capabilities, settings = lua_settings })
  setup_lsp('bashls', { capabilities = capabilities, filetypes = bashls_filetypes })
end

local lspconfig = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  config = config,
}

return {
  lspconfig,
}
