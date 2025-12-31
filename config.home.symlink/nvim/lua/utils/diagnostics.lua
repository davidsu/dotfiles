-- Diagnostic Display Utilities
-- Functions for showing diagnostic messages in command line

local M = {}

-- Track if we're currently showing a diagnostic message
local showing_diagnostic = false

-- Show diagnostic message in command line for diagnostic at cursor position
function M.show_diagnostic_at_cursor()
  -- Wrap entire function in pcall to catch any errors silently
  local ok, err = pcall(function()
    -- Validate buffer is normal and valid
    local bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    
    -- Skip special buffer types
    local buftype = vim.bo[bufnr].buftype
    if buftype ~= '' then
      return
    end
    
    local line = vim.fn.line('.') - 1  -- 0-indexed for diagnostics API
    local col = vim.fn.col('.') - 1    -- 0-indexed
    
    -- Validate position values
    if not line or line < 0 or not col or col < 0 then
      return
    end
    
    -- Get all diagnostics on current line
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
    
    -- Validate diagnostics result
    if not diagnostics or type(diagnostics) ~= 'table' then
      return
    end
    
    -- Find diagnostic that covers current cursor position
    local current_diag = nil
    for _, diag in ipairs(diagnostics) do
      if diag and type(diag) == 'table' and diag.col then
        local diag_start = diag.col
        local diag_end = diag.end_col or diag.col
        
        if col >= diag_start and col <= diag_end then
          current_diag = diag
          break
        end
      end
    end
    
    if current_diag and current_diag.message then
      -- Validate diagnostic has required fields
      if not current_diag.severity then
        return
      end
      
      -- Show diagnostic message in command line with appropriate highlight
      local severity_hl = {
        [vim.diagnostic.severity.ERROR] = 'DiagnosticError',
        [vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
        [vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
        [vim.diagnostic.severity.HINT] = 'DiagnosticHint',
      }
      local hl = severity_hl[current_diag.severity] or 'DiagnosticWarn'
      local source = current_diag.source or ''
      
      -- Build message safely (escape % to prevent string.format issues)
      local diag_message = tostring(current_diag.message):gsub('%%', '%%%%')
      local message = source ~= '' and (source .. ': ' .. diag_message) or diag_message
      
      vim.api.nvim_echo({{ message, hl }}, false, {})
      showing_diagnostic = true
    else
      -- No diagnostic under cursor, clear if we were showing one
      if showing_diagnostic then
        vim.api.nvim_echo({{ '' }}, false, {})
        showing_diagnostic = false
      end
    end
  end)
  
  -- Silently ignore any errors - don't spam the user with red error messages
  if not ok then
    -- Optionally log error for debugging (comment out in production)
    -- vim.notify('Diagnostic display error: ' .. tostring(err), vim.log.levels.DEBUG)
  end
end

return M

