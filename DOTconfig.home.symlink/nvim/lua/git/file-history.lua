-- File history viewer showing git log for current file
-- Usage: :Gfh or :GitFileHistory

local git = require("git.helpers")

-- Git helpers

local function get_file_log(filepath, limit)
  limit = limit or 100
  local output, ok = git.run(string.format("log -n %d --name-status --follow -- %s", limit, vim.fn.shellescape(filepath)))
  if not ok then return nil end
  return output
end

-- UI: Syntax highlighting

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match gfhCommit /^commit [a-f0-9]\+/
      syn match gfhAuthor /^Author:.*$/
      syn match gfhDate /^Date:.*$/
      syn match gfhModified /^M\t/ nextgroup=gfhPath
      syn match gfhAdded /^A\t/ nextgroup=gfhPath
      syn match gfhDeleted /^D\t/ nextgroup=gfhPath
      syn match gfhRenamed /^R[0-9]*\t/ nextgroup=gfhPath
      syn match gfhPath /.*$/ contained

      hi def link gfhCommit Type
      hi def link gfhAuthor Normal
      hi def link gfhDate Comment
      hi def link gfhModified Type
      hi def link gfhAdded DiffAdd
      hi def link gfhDeleted DiffDelete
      hi def link gfhRenamed Special
      hi def link gfhPath Normal

      let b:current_syntax = "gfh"
    ]])
  end)
end

-- UI: Log parsing

local function parse_log(lines)
  local commits = {}
  local line_to_commit = {}
  local current_commit = nil

  for i, line in ipairs(lines) do
    local sha = line:match("^commit ([a-f0-9]+)")
    if sha then
      current_commit = sha
      table.insert(commits, { sha = sha, line = i })
    end
    line_to_commit[i] = current_commit
  end

  return commits, line_to_commit
end

local function get_commit_pair(commits, line_to_commit, cursor_line)
  local current_sha = line_to_commit[cursor_line]
  if not current_sha then return nil, nil end

  for i, commit in ipairs(commits) do
    if commit.sha == current_sha then
      local next_commit = commits[i + 1]
      local next_sha = next_commit and next_commit.sha or nil
      return current_sha, next_sha
    end
  end
  return current_sha, nil
end

local function get_commit_at_cursor(line_to_commit)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  return line_to_commit[cursor_line]
end

-- UI: Actions

local function show_help()
  vim.notify(
    "Gfh keymaps:\n  dd    Show diff (this commit vs parent)\n  <CR>  Open file at commit\n  q     Close\n  g?    Help",
    vim.log.levels.INFO
  )
end

-- UI: Buffer setup

local function create_buffer(filepath, log_output)
  local bufnr = git.create_scratch_buffer()
  local lines = vim.split(log_output, "\n", { plain = true })

  git.set_buffer_lines(bufnr, lines)

  local short_path = vim.fn.fnamemodify(filepath, ":~:.")
  vim.api.nvim_buf_set_name(bufnr, "gfh://" .. short_path)

  local commits, line_to_commit = parse_log(lines)

  setup_syntax(bufnr)

  git.map(bufnr, "dd", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local current, parent = get_commit_pair(commits, line_to_commit, cursor_line)
    if not current then
      return vim.notify("No commit at cursor", vim.log.levels.WARN)
    end
    git.show_diff(current, parent, filepath)
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

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- Main function

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
