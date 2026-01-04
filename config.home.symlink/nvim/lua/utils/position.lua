local function find_signature_position()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Search forward for opening paren on same line
  local paren_col = line:find('%(', col + 1)
  if paren_col then
    -- Return position inside the parens (after opening paren)
    return { line = vim.fn.line('.') - 1, character = paren_col }
  end

  return nil
end

return {
  find_signature_position = find_signature_position,
}
