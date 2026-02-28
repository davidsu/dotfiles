-- Diagnostic Display Utilities
-- Functions for showing diagnostic messages in command line

local showing_diagnostic = false

local severity_highlights = {
  [vim.diagnostic.severity.ERROR] = 'DiagnosticError',
  [vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
  [vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
  [vim.diagnostic.severity.HINT] = 'DiagnosticHint',
}

local function validate_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local buftype = vim.bo[bufnr].buftype
  if buftype ~= '' then
    return nil
  end

  return bufnr
end

local function get_diagnostic_at_cursor(bufnr)
  local line = vim.fn.line('.') - 1
  local col = vim.fn.col('.') - 1

  if not line or line < 0 or not col or col < 0 then
    return nil
  end

  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
  if not diagnostics or type(diagnostics) ~= 'table' then
    return nil
  end

  for _, diag in ipairs(diagnostics) do
    if diag and type(diag) == 'table' and diag.col then
      local diag_start = diag.col
      local diag_end = diag.end_col or diag.col

      if col >= diag_start and col <= diag_end then
        return diag
      end
    end
  end

  return nil
end

local function display_diagnostic_message(diag)
  if not diag.severity then
    return
  end

  local hl = severity_highlights[diag.severity] or 'DiagnosticWarn'
  local source = diag.source or ''
  local diag_message = tostring(diag.message):gsub('%%', '%%%%')
  local message = source ~= '' and (source .. ': ' .. diag_message) or diag_message

  vim.api.nvim_echo({{ message, hl }}, false, {})
  showing_diagnostic = true
end

local function clear_diagnostic_message()
  if showing_diagnostic then
    vim.api.nvim_echo({{ '' }}, false, {})
    showing_diagnostic = false
  end
end

local function show_diagnostic_at_cursor()
  pcall(function()
    local bufnr = validate_buffer()
    if not bufnr then
      clear_diagnostic_message()
      return
    end

    local diag = get_diagnostic_at_cursor(bufnr)
    if diag and diag.message then
      display_diagnostic_message(diag)
    else
      clear_diagnostic_message()
    end
  end)
end

return {
  show_diagnostic_at_cursor = show_diagnostic_at_cursor,
}
