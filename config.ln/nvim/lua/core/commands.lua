-- Core User Commands
-- User-defined commands (not keymaps)


-- Copy to system clipboard helper
local function to_clipboard(value)
  vim.fn.setreg('+', value)
  vim.notify('Copied: ' .. value)
end

local function line_span(opts)
  if opts.line1 == opts.line2 then return ':' .. opts.line1 end
  return ':' .. opts.line1 .. '-' .. opts.line2
end

local function line_suffix(opts)
  return opts.range == 0 and '' or line_span(opts)
end

local function file_path_copier(lines_of)
  return function(opts)
    to_clipboard(vim.fn.expand('%:p') .. lines_of(opts))
  end
end

local copy_file_path = file_path_copier(line_suffix)
local copy_file_path_opts = { range = true, desc = 'Copy full file path (with {from}-{to} lines when given a range) to clipboard' }

vim.api.nvim_create_user_command('P', copy_file_path, copy_file_path_opts)

vim.api.nvim_create_user_command('PP', file_path_copier(line_span),
  { range = true, desc = 'Copy full file path with line number (or {from}-{to} range) to clipboard' })

vim.api.nvim_create_user_command('PPP', function()
  local path = vim.fn.expand('%:p')
  local line = vim.fn.line('.')
  local col = vim.fn.col('.')
  to_clipboard(path .. ':' .. line .. ':' .. col)
end, { desc = 'Copy full file path with line and column to clipboard' })

vim.api.nvim_create_user_command('CopyFilePath', copy_file_path, copy_file_path_opts)

vim.api.nvim_create_user_command('CopyFileName', function()
  to_clipboard(vim.fn.expand('%:t'))
end, { desc = 'Copy file name to clipboard' })

vim.api.nvim_create_user_command('CopyFileNameNoExtension', function()
  to_clipboard(vim.fn.expand('%:t:r'))
end, { desc = 'Copy file name without extension to clipboard' })

vim.api.nvim_create_user_command('CopyRelativeFilePath', function()
  to_clipboard(vim.fn.expand('%:.'))
end, { desc = 'Copy relative file path to clipboard' })

-- Toggle signs (sign column, gitsigns, diagnostics)
local signs_enabled = false
vim.api.nvim_create_user_command('Signs', function()
  signs_enabled = not signs_enabled
  vim.opt.signcolumn = signs_enabled and 'yes' or 'no'

  -- Toggle gitsigns if available
  local gs_ok, gitsigns = pcall(require, 'gitsigns')
  if gs_ok then
    gitsigns.toggle_signs(signs_enabled)
  end

  -- Toggle diagnostic signs
  vim.diagnostic.config({ signs = signs_enabled })

  vim.notify('Signs ' .. (signs_enabled and 'enabled' or 'disabled'))
end, { desc = 'Toggle sign column and all signs' })
