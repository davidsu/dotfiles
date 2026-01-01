-- Enhanced folding with comment block support

local function is_comment_line(bufnr, lnum)
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
  if not line then return false end

  local trimmed = line:match("^%s*(.*)")
  if not trimmed or trimmed == "" then return false end

  -- Single-line comments
  if trimmed:sub(1, 2) == "//" then return true end
  -- Block comment start/continuation/end
  if trimmed:sub(1, 2) == "/*" then return true end
  if trimmed:sub(1, 1) == "*" then return true end
  -- Lua comments
  if trimmed:sub(1, 2) == "--" then return true end

  return false
end

local function is_starting_comment_block(bufnr, lnum)
  local curr_is_comment = is_comment_line(bufnr, lnum)
  local prev_is_comment = lnum > 1 and is_comment_line(bufnr, lnum - 1) or false
  return curr_is_comment and not prev_is_comment
end

local function is_in_middle_of_comment_block(bufnr, lnum)
  local curr_is_comment = is_comment_line(bufnr, lnum)
  local next_is_comment = is_comment_line(bufnr, lnum + 1)
  return curr_is_comment and next_is_comment
end

local function is_ending_comment_block(bufnr, lnum)
  local curr_is_comment = is_comment_line(bufnr, lnum)
  local next_is_comment = is_comment_line(bufnr, lnum + 1)
  return curr_is_comment and not next_is_comment
end

local function get_treesitter_fold()
  local ok, ts_fold = pcall(vim.treesitter.foldexpr)
  if ok and ts_fold and ts_fold ~= "0" then
    return ts_fold
  end
  return nil
end

local function foldexpr_with_comments()
  local lnum = vim.v.lnum
  local bufnr = vim.api.nvim_get_current_buf()

  local ts_fold = get_treesitter_fold()
  if ts_fold then return ts_fold end

  if is_starting_comment_block(bufnr, lnum) then return ">1" end
  if is_in_middle_of_comment_block(bufnr, lnum) then return "1" end
  if is_ending_comment_block(bufnr, lnum) then return "<1" end

  return "0"
end

local function fold_range(start_line, end_line)
  local fold_cmd = string.format("%d,%dfold", start_line, end_line)
  pcall(function() vim.cmd(fold_cmd) end)
end

local function fold_trailing_comment(in_comment, comment_start)
  if in_comment and comment_start > 0 then
    local fold_cmd = string.format("%d,$fold", comment_start)
    pcall(function() vim.cmd(fold_cmd) end)
  end
end

local function fold_all_comment_blocks(bufnr, lines)
  local in_comment = false
  local comment_start = 0

  for i in ipairs(lines) do
    local is_comment = is_comment_line(bufnr, i)

    if is_comment and not in_comment then
      in_comment = true
      comment_start = i
    elseif not is_comment and in_comment then
      fold_range(comment_start, i - 1)
      in_comment = false
    end
  end

  return in_comment, comment_start
end

local function fold_comments_only()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local in_comment, comment_start = fold_all_comment_blocks(bufnr, lines)
  fold_trailing_comment(in_comment, comment_start)
end

local function unfold_comments_only()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i in ipairs(lines) do
    if is_comment_line(bufnr, i) then
      vim.cmd(i .. "foldopen!")
    end
  end
end

return {
  fold_comments_only = fold_comments_only,
  foldexpr_with_comments = foldexpr_with_comments,
  unfold_comments_only = unfold_comments_only,
}
