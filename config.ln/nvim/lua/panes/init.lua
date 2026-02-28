-- Window management for split-pane layouts
-- Supports 3 layouts:
-- 1. List (top) + Single detail (bottom)
-- 2. List (top) + Two-way diff (bottom left/right)
-- 3. Fullscreen detail (no list)
--
-- Tab-scoped: Each tab maintains independent pane state
-- Uses vim.t.pane_list_win and vim.t.pane_detail_wins

local function list_height()
  return math.floor(vim.o.lines * 0.35)
end

-- Vim split commands
local TOP_SPLIT = 'topleft split'
local BOTTOM_SPLIT = 'botright split'
local VERTICAL_SPLIT = 'rightbelow vsplit'

local function get_list_window()
  if vim.t.pane_list_win and vim.api.nvim_win_is_valid(vim.t.pane_list_win) then
    return vim.t.pane_list_win
  end
  return nil
end

local function focus_list_window()
  local list_win = get_list_window()
  if list_win then
    vim.api.nvim_set_current_win(list_win)
    return true
  end
  return false
end

local function close_list_window()
  local list_win = get_list_window()
  if list_win then
    vim.api.nvim_win_close(list_win, true)
    vim.t.pane_list_win = nil
  end
end

local function get_current_line()
  return vim.api.nvim_get_current_line()
end

local function close_all_except_list()
  local list_win = vim.t.pane_list_win
  local current_tab = vim.api.nvim_get_current_tabpage()
  local all_wins = vim.api.nvim_tabpage_list_wins(current_tab)

  for _, winid in ipairs(all_wins) do
    if winid ~= list_win and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.t.pane_detail_wins = nil
end

local function close_all_details()
  if vim.t.pane_detail_wins then
    for _, winid in ipairs(vim.t.pane_detail_wins) do
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
      end
    end
  end
  vim.t.pane_detail_wins = nil
end

local function save_list_state(list_win)
  list_win = list_win or get_list_window()
  if not list_win then return nil end
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(list_win)
  local state = {
    win = list_win,
    view = vim.fn.winsaveview(),
    height = vim.api.nvim_win_get_height(list_win),
  }
  vim.api.nvim_set_current_win(current_win)
  return state
end

local function restore_list_state(list_win_or_state, state)
  -- Support both (state) and (win, state) calling conventions
  if state == nil then
    state = list_win_or_state
    list_win_or_state = state and state.win or nil
  end
  if not list_win_or_state or not state then return end
  if not vim.api.nvim_win_is_valid(list_win_or_state) then return end
  vim.api.nvim_win_set_height(list_win_or_state, state.height)
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(list_win_or_state)
  vim.fn.winrestview(state.view)
  vim.api.nvim_set_current_win(current_win)
end

local function show_single_detail(bufnr)
  local list_win = get_list_window()
  local list_state = save_list_state(list_win)

  close_all_except_list()

  vim.cmd(BOTTOM_SPLIT)
  local detail_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(detail_win, bufnr)
  vim.t.pane_detail_wins = {detail_win}

  restore_list_state(list_win, list_state)
end

local function show_diff_detail(left_bufnr, right_bufnr)
  local list_win = get_list_window()
  local list_state = save_list_state(list_win)

  close_all_except_list()

  vim.cmd(BOTTOM_SPLIT)
  local bottom_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(bottom_win, left_bufnr)

  vim.cmd(VERTICAL_SPLIT)
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_bufnr)

  vim.t.pane_detail_wins = {bottom_win, right_win}

  restore_list_state(list_win, list_state)
end

local function create_list_buffer(config)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, config.lines)
  vim.bo[bufnr].modifiable = false

  if config.name then
    vim.api.nvim_buf_set_name(bufnr, config.name)
  end

  if config.syntax then
    config.syntax(bufnr)
  end

  return bufnr
end

local function setup_list_window(bufnr, use_current_window)
  local list_win = vim.t.pane_list_win

  if list_win and vim.api.nvim_win_is_valid(list_win) then
    vim.api.nvim_win_set_buf(list_win, bufnr)
    vim.api.nvim_set_current_win(list_win)
  elseif use_current_window then
    -- Use current window as list window (for new tabs)
    -- Don't set height - let it stay full screen until detail pane is created
    vim.t.pane_list_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(vim.t.pane_list_win, bufnr)
  else
    vim.cmd(TOP_SPLIT)
    vim.t.pane_list_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(vim.t.pane_list_win, list_height())
    vim.api.nvim_win_set_buf(vim.t.pane_list_win, bufnr)
  end
end

local function setup_keymaps(bufnr, config)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',
    '<cmd>lua require("panes").close_list_window()<CR>',
    { silent = true, noremap = true })

  if config.on_select then
    vim.keymap.set('n', '<CR>', function()
      local line = get_current_line()
      local detail_bufnr = config.on_select(line)
      if detail_bufnr then
        show_single_detail(detail_bufnr)
      end
    end, { buffer = bufnr, silent = true })
  end

  if config.keymaps then
    for _, keymap in ipairs(config.keymaps) do
      vim.keymap.set('n', keymap.key, function()
        local line = get_current_line()
        keymap.fn(line)
      end, { buffer = bufnr, silent = true })
    end
  end
end

local function show_list(config)
  local bufnr = create_list_buffer(config)
  setup_list_window(bufnr, config.use_current_window)
  setup_keymaps(bufnr, config)

  if config.cursor then
    vim.api.nvim_buf_call(bufnr, function()
      vim.api.nvim_win_set_cursor(0, config.cursor)
    end)
  end
end

local function toggle_fullscreen()
  local list_win = vim.t.pane_list_win

  if list_win and vim.api.nvim_win_is_valid(list_win) then
    -- Hide list window
    vim.api.nvim_win_close(list_win, true)
    vim.t.pane_list_win = nil
  else
    -- Can't restore without knowing what buffer to show
    -- Caller must handle re-showing the list
    error("Cannot toggle fullscreen: no list window to restore")
  end
end

return {
  show_list = show_list,
  show_single_detail = show_single_detail,
  show_diff_detail = show_diff_detail,
  close_all_details = close_all_details,
  close_all_except_list = close_all_except_list,
  close_list_window = close_list_window,
  focus_list_window = focus_list_window,
  save_list_state = save_list_state,
  restore_list_state = restore_list_state,
  toggle_fullscreen = toggle_fullscreen,
}
