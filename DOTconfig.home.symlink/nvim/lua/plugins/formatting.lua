-- Formatting Configuration
-- conform.nvim for code formatting with Prettier

local function get_formatters_by_ft()
  return {
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    json = { 'prettier' },
    css = { 'prettier' },
    html = { 'prettier' },
    markdown = { 'prettier' },
    yaml = { 'prettier' },
  }
end

local function format_on_save(bufnr)
  -- Disable autoformat on certain filetypes
  local disable_filetypes = { c = true, cpp = true }
  if disable_filetypes[vim.bo[bufnr].filetype] then
    return nil
  end

  return {
    timeout_ms = 2000,     -- 2 seconds timeout (Prettier can be slow on first run)
    lsp_fallback = true,   -- Use LSP formatting if prettier not available
  }
end

local function create_format_command(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line:len() },
    }
  end
  require('conform').format({ async = true, lsp_fallback = true, range = range })
end

local function config()
  require('conform').setup({
    formatters_by_ft = get_formatters_by_ft(),
    format_on_save = format_on_save,
    formatters = {},
  })

  vim.api.nvim_create_user_command('Format', create_format_command, { range = true })
end

return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    config = config,
  },
}
