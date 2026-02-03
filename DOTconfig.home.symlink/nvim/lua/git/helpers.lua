-- Shared git operations and UI utilities

-- Git operations

local function run(cmd)
  local output = vim.fn.system("git " .. cmd .. " 2>/dev/null")
  local success = vim.v.shell_error == 0
  return output:gsub("%s+$", ""), success
end

local function in_repo()
  local _, ok = run("rev-parse --git-dir")
  return ok
end

local function resolve_commit(ref)
  local sha, ok = run("rev-parse " .. ref)
  return ok and sha or nil
end

local function list_branches()
  local output = run("branch --format='%(refname:short)'")
  local branches = {}
  for branch in output:gmatch("[^\n]+") do
    table.insert(branches, branch)
  end
  return branches
end

local function to_repo_relative_path(filepath)
  local git_root, ok = run("rev-parse --show-toplevel")
  if not ok then
    return filepath
  end

  -- Make sure both paths are absolute and normalized
  local abs_filepath = vim.fn.fnamemodify(filepath, ":p")
  local abs_git_root = vim.fn.fnamemodify(git_root, ":p")

  -- Remove git root from filepath
  if abs_filepath:sub(1, #abs_git_root) == abs_git_root then
    return abs_filepath:sub(#abs_git_root + 1)
  end

  return filepath
end

-- Buffer utilities

local function close_diff_windows()
  local current_win = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current_win then
      local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      if bufname:match("^fugitive://") or vim.wo[win].diff then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
  vim.cmd("diffoff!")
end

local function create_scratch_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  return bufnr
end

local function set_buffer_lines(bufnr, lines)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

local function map(bufnr, key, fn)
  vim.keymap.set("n", key, fn, { buffer = bufnr, silent = true })
end

-- Fugitive actions

local function open_file(commit, filepath)
  vim.cmd("Gedit " .. commit .. ":" .. filepath)
end

local function open_split(commit, filepath)
  vim.cmd("Gsplit " .. commit .. ":" .. filepath)
end

local function show_file_in_pane(commit, filepath)
  local panes = require('panes')
  panes.close_all_except_list()
  panes.focus_list_window()

  vim.cmd("below split")
  vim.cmd("Gedit " .. commit .. ":" .. filepath)

  panes.focus_list_window()
end

local function show_diff(commit, parent, filepath)
  local panes = require('panes')
  panes.close_all_except_list()
  panes.focus_list_window()

  vim.cmd("below split")
  vim.cmd("Gedit " .. commit .. ":" .. filepath)
  if parent then
    -- Suppress error if file doesn't exist in parent commit
    vim.cmd("silent! Gvdiffsplit " .. parent .. ":" .. filepath)
  end

  -- Leave focus in detail pane (consistent with Fugitive behavior)
end

return {
  run = run,
  in_repo = in_repo,
  resolve_commit = resolve_commit,
  list_branches = list_branches,
  to_repo_relative_path = to_repo_relative_path,
  close_diff_windows = close_diff_windows,
  create_scratch_buffer = create_scratch_buffer,
  set_buffer_lines = set_buffer_lines,
  map = map,
  open_file = open_file,
  open_split = open_split,
  show_file_in_pane = show_file_in_pane,
  show_diff = show_diff,
}
