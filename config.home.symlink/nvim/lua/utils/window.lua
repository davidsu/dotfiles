-- Window Utility Functions
-- Smart window navigation that creates splits at edges

local M = {}

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

return M

