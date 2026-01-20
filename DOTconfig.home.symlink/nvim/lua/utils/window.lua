-- Window Utility Functions
-- Smart window navigation and resizing

local force_horizontal_resize = false

local function win_move(key)
  local curr_win = vim.fn.winnr()
  vim.cmd('wincmd ' .. key)

  if curr_win == vim.fn.winnr() then
    if key == 'h' or key == 'l' then
      vim.cmd('wincmd v')
    else
      vim.cmd('wincmd s')
    end
    vim.cmd('wincmd ' .. key)
  end
end

local function horizontal_resize(key)
  local winheight = vim.fn.winheight(0)
  if key == '+' then
    vim.cmd('5wincmd +')
  else
    vim.cmd('5wincmd -')
  end
  if winheight == vim.fn.winheight(0) then
    force_horizontal_resize = false
  end
end

local function win_size(key)
  if force_horizontal_resize then
    horizontal_resize(key)
    return
  end

  local curr_win = vim.fn.winnr()
  vim.cmd('wincmd l')

  if curr_win == vim.fn.winnr() then
    vim.cmd('wincmd h')
    if curr_win == vim.fn.winnr() then
      horizontal_resize(key)
      return
    end
    vim.cmd('wincmd l')
  else
    vim.cmd('wincmd h')
  end

  if key == '+' then
    vim.cmd('5wincmd >')
  else
    vim.cmd('5wincmd <')
  end
end

local function toggle_force_horizontal_resize()
  force_horizontal_resize = not force_horizontal_resize
  print(force_horizontal_resize and 'Forcing horizontal resize' or 'Auto-detect resize')
end

return {
  win_move = win_move,
  win_size = win_size,
  toggle_force_horizontal_resize = toggle_force_horizontal_resize,
}

