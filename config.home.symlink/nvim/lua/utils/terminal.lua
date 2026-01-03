-- Terminal Utility Functions

-- Private functions
local function find_terminal_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == 'terminal' then
      return buf
    end
  end
  return nil
end

local function focus_terminal_if_visible()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(current_tab)

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      vim.api.nvim_set_current_win(win)
      return true
    end
  end

  return false
end

local function open_terminal()
  local term_buf = find_terminal_buffer()

  local current_win = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(current_win)
  if vim.fn.winnr('$') == 1 and config.width > 140 then
    require('utils.window').win_move('l')
  end

  if term_buf then
    vim.api.nvim_buf_set_option(term_buf, 'buflisted', true)
    vim.cmd('buffer ' .. term_buf)
  else
    vim.cmd('terminal')
  end
end

-- Public API
local function to_terminal()
  if not focus_terminal_if_visible() then
    open_terminal()
  end
  vim.cmd('startinsert')
end

return {
  to_terminal = to_terminal,
}
