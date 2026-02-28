-- K key behavior:
-- - If on fold: show fold contents
-- - Otherwise: cycle between diagnostic <-> LSP hover
-- Resets state when any floating window closes

local isShowingDiagnostic = true

local function has_diagnostic()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  return #diagnostics > 0
end

local function k_cycle()
  -- First, check if we're on a folded line
  local winid = require('ufo').peekFoldedLinesUnderCursor()
  if winid then
    -- On a fold, just show it (don't cycle)
    return
  end

  if isShowingDiagnostic and has_diagnostic() then
    vim.diagnostic.open_float({ border = 'rounded', focusable = false })
    isShowingDiagnostic = false
    return
  end

  vim.lsp.buf.hover()
  isShowingDiagnostic = true
end

return {
  k_cycle = k_cycle,
}
