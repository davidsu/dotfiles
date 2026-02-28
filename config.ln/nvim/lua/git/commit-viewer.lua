-- Reusable commit details viewer
-- Shows git show --name-status output for any commit

local git = require("git.helpers")

local function get_commit_details(sha)
  local output, ok = git.run(string.format("show --name-status %s", sha))
  if not ok then return nil end
  return output
end

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match commitViewerCommit /^commit [a-f0-9]\+/
      syn match commitViewerAuthor /^Author:.*$/
      syn match commitViewerDate /^Date:.*$/
      syn match commitViewerModified /^M\t/ nextgroup=commitViewerPath
      syn match commitViewerAdded /^A\t/ nextgroup=commitViewerPath
      syn match commitViewerDeleted /^D\t/ nextgroup=commitViewerPath
      syn match commitViewerRenamed /^R[0-9]*\t/ nextgroup=commitViewerPath
      syn match commitViewerPath /.*$/ contained

      hi def link commitViewerCommit Type
      hi def link commitViewerAuthor Normal
      hi def link commitViewerDate Comment
      hi def link commitViewerModified Type
      hi def link commitViewerAdded DiffAdd
      hi def link commitViewerDeleted DiffDelete
      hi def link commitViewerRenamed Special
      hi def link commitViewerPath Normal

      let b:current_syntax = "commit_viewer"
    ]])
  end)
end

local function create_buffer(sha, details)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

  local lines = vim.split(details, "\n", { plain = true })
  git.set_buffer_lines(bufnr, lines)
  vim.api.nvim_buf_set_name(bufnr, "commit-viewer://" .. sha)
  setup_syntax(bufnr)

  return bufnr
end

local function setup_keymaps(bufnr, sha, return_win)
  git.map(bufnr, "q", function()
    vim.cmd("bdelete")
    if return_win and vim.api.nvim_win_is_valid(return_win) then
      vim.api.nvim_set_current_win(return_win)
    end
  end)

  git.map(bufnr, "dd", function()
    local line = vim.api.nvim_get_current_line()
    local file_path = line:match("^[MADR][0-9]*%s+(.+)$")
    if not file_path then
      return vim.notify("No file on this line", vim.log.levels.WARN)
    end

    -- Navigate to bottom window and replace it with diff
    vim.cmd("wincmd b")
    git.close_diff_windows()
    vim.cmd("Gedit " .. sha .. ":" .. file_path)
    vim.cmd("Gvdiffsplit " .. sha .. "^:" .. file_path)
  end)
end

local function show(sha, return_win)
  if not sha then
    return vim.notify("No commit SHA provided", vim.log.levels.WARN)
  end

  local details = get_commit_details(sha)
  if not details then
    return vim.notify("Failed to get commit details", vim.log.levels.ERROR)
  end

  local bufnr = create_buffer(sha, details)

  vim.cmd("rightbelow vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)

  setup_keymaps(bufnr, sha, return_win)

  if return_win and vim.api.nvim_win_is_valid(return_win) then
    vim.api.nvim_set_current_win(return_win)
  end
end

return { show = show }
