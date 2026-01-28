-- File history viewer showing git log for current file
-- Usage: :Gfh or :GitFileHistory

local git = require("git.helpers")
local commit_viewer = require("git.commit-viewer")

-- Git helpers

local function get_file_log(filepath, limit)
  limit = limit or 100
  local output, ok = git.run(string.format("log -n %d --oneline --follow -- %s", limit, vim.fn.shellescape(filepath)))
  if not ok then return nil end
  return output
end

-- UI: Syntax highlighting

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match gfhSha /^[a-f0-9]\{7,\}/ nextgroup=gfhMessage
      syn match gfhMessage / .*$/ contained

      hi def link gfhSha Type
      hi def link gfhMessage Normal

      let b:current_syntax = "gfh"
    ]])
  end)
end

-- UI: Log parsing

local function parse_log(lines)
  local commits = {}
  local line_to_commit = {}

  for i, line in ipairs(lines) do
    local sha = line:match("^([a-f0-9]+)")
    if sha then
      table.insert(commits, { sha = sha, line = i })
      line_to_commit[i] = sha
    end
  end

  return commits, line_to_commit
end

local function get_commit_pair(commits, cursor_line)
  for i, commit in ipairs(commits) do
    if commit.line == cursor_line then
      local next_commit = commits[i + 1]
      local next_sha = next_commit and next_commit.sha or nil
      return commit.sha, next_sha
    end
  end
  return nil, nil
end

local function get_commit_at_cursor(line_to_commit)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  return line_to_commit[cursor_line]
end

-- UI: Actions

local function find_commit_sha(commits, cursor_line)
  for _, commit in ipairs(commits) do
    if commit.line == cursor_line then
      return commit.sha
    end
  end
  return nil
end

local function show_commit_details(commits, cursor_line)
  local sha = find_commit_sha(commits, cursor_line)
  if not sha then
    return vim.notify("No commit at cursor", vim.log.levels.WARN)
  end

  local history_win = vim.api.nvim_get_current_win()
  commit_viewer.show(sha, history_win)
end

local function show_help()
  vim.notify(
    "Gfh keymaps:\n  <C-s>  Show commit details\n  dd     Show diff (this commit vs parent)\n  <CR>   Open file at commit\n  q      Close\n  g?     Help",
    vim.log.levels.INFO
  )
end

-- UI: Buffer setup

local function create_history_buffer(filepath, log_output)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

  local lines = vim.split(log_output, "\n", { plain = true })
  git.set_buffer_lines(bufnr, lines)

  local short_path = vim.fn.fnamemodify(filepath, ":~:.")
  vim.api.nvim_buf_set_name(bufnr, "gfh://" .. short_path)

  return bufnr, lines
end

local function open_history_window(bufnr)
  local height = math.floor(vim.o.lines * 0.4)
  vim.cmd(string.format("topleft %dsplit", height))
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function setup_history_keymaps(bufnr, commits, line_to_commit, filepath)
  git.map(bufnr, "dd", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local current, parent = get_commit_pair(commits, cursor_line)
    if not current then
      return vim.notify("No commit at cursor", vim.log.levels.WARN)
    end
    git.show_diff(current, parent, filepath)
  end)

  git.map(bufnr, "<C-s>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    show_commit_details(commits, cursor_line)
  end)

  git.map(bufnr, "<CR>", function()
    local sha = get_commit_at_cursor(line_to_commit)
    if not sha then
      return vim.notify("No commit at cursor", vim.log.levels.WARN)
    end
    git.open_file(sha, filepath)
  end)

  git.map(bufnr, "q", function() vim.cmd("bdelete") end)
  git.map(bufnr, "g?", show_help)
end

local function create_buffer(filepath, log_output)
  local bufnr, lines = create_history_buffer(filepath, log_output)
  open_history_window(bufnr)

  local commits, line_to_commit = parse_log(lines)
  setup_syntax(bufnr)
  setup_history_keymaps(bufnr, commits, line_to_commit, filepath)
end

-- Main function

local function close_existing_history_buffers()
  -- First close all windows showing these buffers
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("^gfh://") or bufname:match("^commit%-viewer://") then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- Then wipe all buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("^gfh://") or bufname:match("^commit%-viewer://") then
      pcall(vim.cmd, "bwipeout! " .. bufnr)
    end
  end
end

local function gfh(filepath)
  if not git.in_repo() then
    return vim.notify("Gfh: not in a git repository", vim.log.levels.ERROR)
  end

  if not filepath or filepath == "" then
    filepath = vim.fn.expand("%:p")
  end

  if filepath == "" then
    return vim.notify("Gfh: no file specified", vim.log.levels.ERROR)
  end

  local log = get_file_log(filepath)
  if not log or log == "" then
    return vim.notify("Gfh: no history found for " .. filepath, vim.log.levels.WARN)
  end

  close_existing_history_buffers()
  create_buffer(filepath, log)
end

-- Command registration

local function command_handler(opts)
  local filepath = opts.args ~= "" and opts.args or nil
  gfh(filepath)
end

local command_opts = {
  nargs = "?",
  desc = "Show git log history for file",
  complete = "file",
}

vim.api.nvim_create_user_command("Gfh", command_handler, command_opts)
vim.api.nvim_create_user_command("GitFileHistory", command_handler, command_opts)

-- Keybind: <space>bh for buffer history
vim.keymap.set('n', '<leader>bh', '<cmd>GitFileHistory<cr>', {
  desc = 'Git: Buffer History'
})

return { gfh = gfh }
