-- LSP Configuration
-- Native Neovim Language Server Protocol support

return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      -- Optional: Show LSP progress notifications
      {
        'j-hui/fidget.nvim',
        opts = {
          progress = {
            suppress_on_insert = true,  -- Don't show progress in insert mode
            ignore = {
              'null-ls',  -- Ignore null-ls progress
            },
            display = {
              render_limit = 5,  -- Limit number of messages shown
              done_ttl = 1,      -- Clear "done" messages after 1 second
            },
          },
          notification = {
            window = {
              avoid = { 'NvimTree' }, -- Don't show notifications over nvim-tree
            },
          },
        },
      },
    },
    config = function()
      -- Setup diagnostic display
      vim.diagnostic.config({
        virtual_text = {
          prefix = '●',
        },
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

      -- LSP keybindings (activated when LSP attaches to buffer)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf
          local opts = { buffer = bufnr, silent = true }

          -- Navigation
          vim.keymap.set('n', '<space>cd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

          -- Actions
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'x' }, '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<space>cf', vim.lsp.buf.code_action, opts)

          -- Diagnostics
          vim.keymap.set('n', '<space>lo', vim.diagnostic.setloclist, opts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

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
        end,
      })

      -- Get enhanced capabilities from nvim-cmp if available
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      if has_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- Configure TypeScript language server using modern API
      vim.lsp.config('ts_ls', {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json', '.git' },
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

      -- Enable TypeScript language server
      vim.lsp.enable('ts_ls')

      -- Configure ESLint language server using modern API
      vim.lsp.config('eslint', {
        cmd = { 'vscode-eslint-language-server', '--stdio' },
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        root_markers = { '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', 'eslint.config.js', 'package.json', '.git' },
        capabilities = capabilities,
        settings = {
          format = false,  -- Use conform.nvim for formatting, not ESLint
          run = 'onType',  -- Run ESLint as you type (diagnostics still only show in normal mode due to update_in_insert = false)
        },
      })

      -- Enable ESLint language server
      vim.lsp.enable('eslint')

      -- Note: Formatting on save is now handled by conform.nvim (see plugins/formatting.lua)
      -- ESLint provides diagnostics only, not formatting
    end,
  },
}
