local function indent_of(line_num)
  return #(vim.fn.getline(line_num):match('^%s*'))
end

local function jump_to_parent(step)
  local lnum = vim.fn.line('.')
  local target_indent = indent_of(lnum)
  if target_indent == 0 then return end

  local limit = step > 0 and vim.fn.line('$') or 1
  for candidate = lnum + step, limit, step do
    local line = vim.fn.getline(candidate)
    if line:match('%S') and indent_of(candidate) < target_indent then
      vim.fn.cursor(candidate, indent_of(candidate) + 1)
      return
    end
  end
end

return {
  jump_up = function() jump_to_parent(-1) end,
  jump_down = function() jump_to_parent(1) end,
}
