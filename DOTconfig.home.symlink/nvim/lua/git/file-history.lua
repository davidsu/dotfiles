-- File history viewer showing git log for current file
-- Usage: :Gfh or :GitFileHistory

local git = require("git.helpers")
local panes = require("panes")

-- Git helpers

local function get_file_log(filepath, limit)
  limit = limit or 100
  local cmd = "log -n " .. limit
    .. " --pretty=format:'%h%d %s  %cd  (%an)' --date=short --follow -- "
    .. vim.fn.shellescape(filepath)
  local output, ok = git.run(cmd)
  if not ok then return nil end
  return output
end

-- UI: Syntax highlighting

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match gfhSha /^[a-f0-9]\{7,\}/
      syn match gfhDate /\d\{4\}-\d\{2\}-\d\{2\}/
      syn match gfhAuthor /([^()]\+)$/

      hi def link gfhSha Type
      hi def link gfhDate Comment
      hi def link gfhAuthor String

      let b:current_syntax = "gfh"
    ]])
  end)
end

local function setup_commit_viewer_syntax(bufnr)
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

local function get_sha_from_line(line)
  return line:match("^([a-f0-9]+)")
end

-- UI: Actions

local function create_scratch_buffer(name)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  if name then
    vim.api.nvim_buf_set_name(bufnr, name)
  end
  return bufnr
end

local function open_file_at_commit(sha, filepath)
  if not sha then
    return nil
  end

  -- Expand short SHA to full SHA (fugitive requires full SHA)
  local full_sha = git.resolve_commit(sha)
  if not full_sha then
    return nil
  end

  -- Build fugitive:// path (same pattern as commit-diff.lua)
  local repo_path = git.to_repo_relative_path(filepath)
  local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. full_sha .. "/" .. repo_path

  -- Create buffer without changing current window
  local bufnr = vim.fn.bufadd(fugitive_path)
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].buftype = "nowrite"

  return bufnr
end

local function parse_commit_file_line(line)
  local status, path = line:match("^([MADRCU]%d*)\t(.+)$")
  return status, path
end

local function get_commit_details(sha)
  local cmd = "show --name-status --format='commit %h%nAuthor: %an <%ae>%nDate:   %cd%n%n    %s%n' --date=short " .. sha
  local details, ok = git.run(cmd)
  if not ok or not details then return nil end

  local lines = vim.split(details, "\n", { plain = true })
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  return lines
end

local function show_commit_details_in_new_tab(sha)
  if not sha then
    return vim.notify("No commit at cursor", vim.log.levels.WARN)
  end

  local detail_lines = get_commit_details(sha)
  if not detail_lines then
    return vim.notify("Failed to get commit details", vim.log.levels.WARN)
  end

  -- Expand short SHA to full SHA
  local full_sha = git.resolve_commit(sha)
  if not full_sha then
    return vim.notify("Failed to resolve commit", vim.log.levels.ERROR)
  end

  -- Create new tab with panes layout
  vim.cmd("tabnew")

  panes.show_list({
    lines = detail_lines,
    name = "commit://" .. sha,
    syntax = setup_commit_viewer_syntax,
    cursor = { 1, 0 },
    use_current_window = true,
    on_select = function(line)
      local status, filepath = parse_commit_file_line(line)
      if not filepath then return nil end

      -- Create Fugitive buffer for file at commit
      local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. full_sha .. "/" .. filepath
      local bufnr = vim.fn.bufadd(fugitive_path)
      vim.fn.bufload(bufnr)
      vim.bo[bufnr].buftype = "nowrite"

      return bufnr
    end,
    keymaps = {
      {
        key = "dd",
        fn = function(line)
          local status, filepath = parse_commit_file_line(line)
          if not filepath then
            return vim.notify("No file at cursor", vim.log.levels.WARN)
          end

          git.show_diff(sha, sha .. "^", filepath)
        end,
      },
    },
  })
end

local function show_help()
  vim.notify(
    "Gfh keymaps:\n  <C-s>  Show commit details (new tab)\n  dd     Show diff (this commit vs parent)\n  <CR>   Open file at commit (detail pane)\n  q      Close\n  g?     Help",
    vim.log.levels.INFO
  )
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

  -- Convert to repo-relative path for git commands
  local repo_path = git.to_repo_relative_path(filepath)

  local log = get_file_log(repo_path)
  if not log or log == "" then
    return vim.notify("Gfh: no history found for " .. filepath, vim.log.levels.WARN)
  end

  local lines = vim.split(log, "\n", { plain = true })
  local commits, line_to_commit = parse_log(lines)
  local short_path = vim.fn.fnamemodify(filepath, ":~:.")

  panes.show_list({
    lines = lines,
    name = "gfh://" .. short_path,
    syntax = setup_syntax,
    cursor = { 1, 0 },
    on_select = function(line)
      local sha = get_sha_from_line(line)
      if sha then
        return open_file_at_commit(sha, repo_path)
      end
      return nil
    end,
    keymaps = {
      {
        key = "dd",
        fn = function(line)
          local sha = get_sha_from_line(line)
          if not sha then
            return vim.notify("No commit at cursor", vim.log.levels.WARN)
          end

          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
          local current, parent = get_commit_pair(commits, cursor_line)
          if not current then
            return vim.notify("No commit at cursor", vim.log.levels.WARN)
          end

          git.show_diff(current, parent, repo_path)
        end,
      },
      {
        key = "<C-s>",
        fn = function(line)
          local sha = get_sha_from_line(line)
          show_commit_details_in_new_tab(sha)
        end,
      },
      {
        key = "g?",
        fn = function(line)
          show_help()
        end,
      },
    },
  })
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
