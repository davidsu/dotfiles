-- Window Utility Functions
-- Smart window navigation and resizing

local M = {}

-- Global state for resize mode toggle
M.force_horizontal_resize = false

-- Smart window movement - creates split if at edge
-- If moving to a window fails (at edge), create a split and move there
function M.win_move(key)
  local curr_win = vim.fn.winnr()
  vim.cmd('wincmd ' .. key)
  
  -- If window didn't change, we're at an edge
  if curr_win == vim.fn.winnr() then
    -- Horizontal movement (h/l) needs vertical split (left/right)
    if key == 'h' or key == 'l' then
      vim.cmd('wincmd v')
    -- Vertical movement (j/k) needs horizontal split (top/bottom)
    else
      vim.cmd('wincmd s')
    end
    -- Move to the new split
    vim.cmd('wincmd ' .. key)
  end
end

-- Horizontal resize (for horizontal splits)
local function horizontal_resize(key)
  local winheight = vim.fn.winheight(0)
  if key == '+' then
    vim.cmd('5wincmd +')
  else
    vim.cmd('5wincmd -')
  end
  if winheight == vim.fn.winheight(0) then
    M.force_horizontal_resize = false
  end
end

-- Smart window resize - auto-detects split orientation
-- Resizes width for vertical splits, height for horizontal splits
function M.win_size(key)
  if M.force_horizontal_resize then
    horizontal_resize(key)
    return
  end
  
  local curr_win = vim.fn.winnr()
  vim.cmd('wincmd l')
  
  if curr_win == vim.fn.winnr() then
    vim.cmd('wincmd h')
    if curr_win == vim.fn.winnr() then
      -- Only one window or horizontal split only
      horizontal_resize(key)
      return
    end
    vim.cmd('wincmd l')
  else
    vim.cmd('wincmd h')
  end
  
  -- Resize width for vertical splits
  if key == '+' then
    vim.cmd('5wincmd >')
  else
    vim.cmd('5wincmd <')
  end
end

-- Toggle between horizontal and vertical resize modes
function M.toggle_force_horizontal_resize()
  M.force_horizontal_resize = not M.force_horizontal_resize
  print(M.force_horizontal_resize and 'Forcing horizontal resize' or 'Auto-detect resize')
end

return M

