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

local function resize_step()
  return vim.v.count > 0 and vim.v.count or 5
end

local function horizontal_resize(key)
  local winheight = vim.fn.winheight(0)
  vim.cmd(resize_step() .. 'wincmd ' .. key)
  if winheight == vim.fn.winheight(0) then
    force_horizontal_resize = false
  end
end

local function has_neighbor(direction)
  return vim.fn.winnr(direction) ~= vim.fn.winnr()
end

local function has_vertical_neighbor()
  return has_neighbor('l') or has_neighbor('h')
end

local half_screen_scroll = { h = 'zH', l = 'zL' }

local function scroll_half_screen(direction)
  require('cinnamon').scroll(half_screen_scroll[direction])
end

local function win_move_or_scroll(key)
  if has_neighbor(key) then
    vim.cmd('wincmd ' .. key)
    return
  end
  scroll_half_screen(key)
end

local function win_size(key)
  if force_horizontal_resize then
    horizontal_resize(key)
    return
  end

  if not has_vertical_neighbor() then
    horizontal_resize(key)
    return
  end

  vim.cmd(resize_step() .. 'wincmd ' .. (key == '+' and '>' or '<'))
end

local function toggle_force_horizontal_resize()
  force_horizontal_resize = not force_horizontal_resize
  print(force_horizontal_resize and 'Forcing horizontal resize' or 'Auto-detect resize')
end

return {
  win_move = win_move,
  win_move_or_scroll = win_move_or_scroll,
  scroll_half_screen = scroll_half_screen,
  win_size = win_size,
  resize_step = resize_step,
  toggle_force_horizontal_resize = toggle_force_horizontal_resize,
}

