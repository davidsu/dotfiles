-- LSP Configuration
-- Native Neovim Language Server Protocol support

local bashls_filetypes = { 'sh', 'bash', 'zsh' }
local diagnostic_config = {
  virtual_text = false,
  signs = false, -- signs disabled to prevent gutter flicker
  underline = true,
  update_in_insert = false,
  severity_sort = true,
}

local typescript_settings = {
  typescript = {
    suggest = {
      includeCompletionsForImportStatements = true,
    },
    preferences = {
      importModuleSpecifier = 'relative',
    },
    tsserver_file_config = {
      externalFiles = {
        exclude = { "**/node_modules/**" }
      }
    }
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

local floating_window = require('utils.floating_window')

local function jump_to_prev_diagnostic()
  vim.diagnostic.jump({ count = -1, float = { border = 'rounded' } })
end

local function jump_to_next_diagnostic()
  vim.diagnostic.jump({ count = 1, float = { border = 'rounded' } })
end

local function setup_lsp_commands()
  vim.api.nvim_create_user_command('Diagnostics', function()
    vim.diagnostic.setqflist()
  end, { desc = 'Show all diagnostics in quickfix list' })
end

local function setup_lsp_mappings(client, args)
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
  vim.keymap.set('n', 'K', require('utils.k_cycle').k_cycle, opts)
  vim.keymap.set('n', '<space>k', require('utils.lsp').hover_preview, opts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set({ 'n', 'x' }, '<space>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<space>cf', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<space>lo', vim.diagnostic.setloclist, opts)
  vim.keymap.set('n', '[d', jump_to_prev_diagnostic, opts)
  vim.keymap.set('n', ']d', jump_to_next_diagnostic, opts)

  vim.keymap.set('n', '<space>f', function()
    vim.lsp.buf.format({ async = true })
  end, opts)

  vim.keymap.set('n', '<Esc>', floating_window.close_floating_windows, opts)
end

local function on_lsp_attach(args)
  local client = vim.lsp.get_client_by_id(args.data.client_id)

  setup_lsp_mappings(client, args)
  setup_lsp_commands()
end

local function setup_lsp_autocmds()
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = on_lsp_attach,
  })
end

local function setup_lsp(server_name, config)
  vim.lsp.config(server_name, config)
  vim.lsp.enable(server_name)
end

local function config()
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- Add folding range capabilities for nvim-ufo -> fold comments
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  vim.diagnostic.config(diagnostic_config)

  setup_lsp_autocmds()
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
