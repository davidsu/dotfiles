-- Navigate by indent level

local M = {}

-- Find the indent level of a line
local function get_indent_level(line_num)
  local line = vim.fn.getline(line_num)
  local indent = line:match('^%s*')
  return #indent
end

-- Find the next line up with less indent than current line
function M.jump_up_indent()
  local current_line = vim.fn.line('.')
  local current_indent = get_indent_level(current_line)
  
  -- Search upward for a line with less indent
  for line_num = current_line - 1, 1, -1 do
    local line_content = vim.fn.getline(line_num)
    
    -- Skip blank lines
    if line_content:match('%S') then
      local indent = get_indent_level(line_num)
      
      -- Jump to first line with less indent
      if indent < current_indent then
        vim.fn.cursor(line_num, indent + 1)
        return
      end
    end
  end
  
  -- No less-indented line found, stay at current position
end

-- Find the next line down with less indent than current line
function M.jump_down_indent()
  local current_line = vim.fn.line('.')
  local current_indent = get_indent_level(current_line)
  local last_line = vim.fn.line('$')
  
  -- Search downward for a line with less indent
  for line_num = current_line + 1, last_line do
    local line_content = vim.fn.getline(line_num)
    
    -- Skip blank lines
    if line_content:match('%S') then
      local indent = get_indent_level(line_num)
      
      -- Jump to first line with less indent
      if indent < current_indent then
        vim.fn.cursor(line_num, indent + 1)
        return
      end
    end
  end
  
  -- No less-indented line found, stay at current position
end

return M
