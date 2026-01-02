-- LSP Configuration
-- Native Neovim Language Server Protocol support

local function setup_diagnostics()
  vim.diagnostic.config({
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
  })

  vim.api.nvim_create_autocmd('CursorHold', {
    callback = require('utils.diagnostics').show_diagnostic_at_cursor,
  })
end

local function setup_lsp_keybindings()
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      local bufnr = args.buf
      local opts = { buffer = bufnr, silent = true }

      -- Navigation
      vim.keymap.set('n', '<space>cd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'gD', vim.lsp.buf.type_definition, opts)
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

      -- Actions
      vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set({ 'n', 'x' }, '<space>ca', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', '<space>cf', vim.lsp.buf.code_action, opts)

      -- Diagnostics
      vim.keymap.set('n', '<space>lo', vim.diagnostic.setloclist, opts)
      vim.keymap.set('n', '[d', function()
        vim.diagnostic.jump({ count = -1, float = { border = 'rounded' } })
      end, opts)
      vim.keymap.set('n', ']d', function()
        vim.diagnostic.jump({ count = 1, float = { border = 'rounded' } })
      end, opts)

      -- Formatting
      if client:supports_method('textDocument/formatting') then
        vim.keymap.set('n', '<space>f', function()
          vim.lsp.buf.format({ async = true })
        end, opts)
      end

      -- Close floating windows
      local close_floats = function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= '' then
            vim.api.nvim_win_close(win, false)
          end
        end
      end

      vim.keymap.set('n', '<C-c>', close_floats, opts)
      vim.keymap.set('n', '<Esc>', close_floats, opts)

      -- Enable LSP folding if the client supports it
      if client:supports_method('textDocument/foldingRange') then
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
        vim.opt_local.foldenable = true
        vim.opt_local.foldlevelstart = 99
      end
    end,
  })
end

local function get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if has_cmp then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end
  return capabilities
end

local function setup_typescript_lsp(capabilities)
  vim.lsp.config('ts_ls', {
    capabilities = capabilities,
    settings = {
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
    },
  })
  vim.lsp.enable('ts_ls')
end

local function setup_eslint_lsp(capabilities)
  vim.lsp.config('eslint', {
    capabilities = capabilities,
    settings = {
      format = false,
      run = 'onType',
    },
  })
  vim.lsp.enable('eslint')
end

local function setup_lua_lsp(capabilities)
  vim.lsp.config('lua_ls', {
    capabilities = capabilities,
    settings = {
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
    },
  })
  vim.lsp.enable('lua_ls')
end

local function setup_bash_lsp(capabilities)
  vim.lsp.config('bashls', {
    capabilities = capabilities,
  })
  vim.lsp.enable('bashls')
end

return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      setup_diagnostics()
      setup_lsp_keybindings()

      local capabilities = get_capabilities()

      setup_typescript_lsp(capabilities)
      setup_eslint_lsp(capabilities)
      setup_lua_lsp(capabilities)
      setup_bash_lsp(capabilities)
    end,
  },
}
