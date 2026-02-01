-- Compare two commits with Fugitive-style UI
-- Usage: :Gdc <commit1> <commit2> or :GitDiffCommits <commit1> <commit2>

local git = require("git.helpers")

-- Git helpers

local function get_timestamp(ref)
  local ts = git.run("log -1 --format=%ct " .. ref)
  return tonumber(ts) or 0
end

local function order_by_time(ref1, ref2)
  if get_timestamp(ref1) < get_timestamp(ref2) then
    return ref1, ref2
  end
  return ref2, ref1
end

local function get_changed_files(earlier, later)
  local output, ok = git.run(string.format("diff --name-status %s %s", earlier, later))
  if not ok then return nil end

  local files = {}
  for line in output:gmatch("[^\n]+") do
    local status, path = line:match("^(%a)%s+(.+)$")
    if status and path then
      table.insert(files, { status = status, path = path })
    end
  end
  return files
end

-- UI: Syntax highlighting

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match gdcHeader /^Comparing:.*$/
      syn match gdcCount /^Files changed:.*$/
      syn match gdcModified /^M / nextgroup=gdcPath
      syn match gdcAdded /^+ / nextgroup=gdcPath
      syn match gdcDeleted /^- / nextgroup=gdcPath
      syn match gdcRenamed /^R / nextgroup=gdcPath
      syn match gdcPath /.*$/ contained

      hi def link gdcHeader Label
      hi def link gdcCount Number
      hi def link gdcModified Type
      hi def link gdcAdded DiffAdd
      hi def link gdcDeleted DiffDelete
      hi def link gdcRenamed Special
      hi def link gdcPath Normal

      let b:current_syntax = "gdc"
    ]])
  end)
end

-- UI: Actions

local function parse_file_line()
  local line = vim.api.nvim_get_current_line()
  local status, path = line:match("^(.) (.+)$")
  return status, path
end

local function get_commit_for_status(status, earlier, later)
  return (status == "-") and earlier or later
end

local function close_all()
  git.close_diff_windows()
  vim.cmd("bdelete")
end

local function show_help()
  vim.notify(
    "Gdc keymaps:\n  dd    Diff split (M) or view file (+/-)\n  <CR>  Open file\n  o     Horizontal split\n  q     Close all",
    vim.log.levels.INFO
  )
end

-- UI: Buffer setup

local function format_status(status)
  local icons = { M = "M", A = "+", D = "-", R = "R", C = "C" }
  return icons[status] or status
end

local function create_buffer(earlier, later, files)
  local bufnr = git.create_scratch_buffer()

  local lines = {
    string.format("Comparing: %s → %s", earlier:sub(1, 8), later:sub(1, 8)),
    string.format("Files changed: %d", #files),
    "",
  }
  for _, file in ipairs(files) do
    table.insert(lines, format_status(file.status) .. " " .. file.path)
  end

  git.set_buffer_lines(bufnr, lines)
  vim.api.nvim_buf_set_name(bufnr, string.format("gdc://%s..%s", earlier:sub(1, 8), later:sub(1, 8)))

  setup_syntax(bufnr)

  git.map(bufnr, "dd", function()
    local status, filepath = parse_file_line()
    if not filepath then return end
    if status == "+" or status == "-" then
      git.open_file(get_commit_for_status(status, earlier, later), filepath)
    else
      git.show_diff(later, earlier, filepath)
    end
  end)
  git.map(bufnr, "<CR>", function()
    local status, filepath = parse_file_line()
    if filepath then git.open_file(get_commit_for_status(status, earlier, later), filepath) end
  end)
  git.map(bufnr, "o", function()
    local status, filepath = parse_file_line()
    if filepath then git.open_split(get_commit_for_status(status, earlier, later), filepath) end
  end)
  git.map(bufnr, "q", close_all)
  git.map(bufnr, "g?", show_help)

  vim.api.nvim_win_set_cursor(0, { 4, 0 })
end

-- Main function

local function gdc(commit1, commit2)
  if not git.in_repo() then
    return vim.notify("Gdc: not in a git repository", vim.log.levels.ERROR)
  end

  local sha1 = git.resolve_commit(commit1)
  local sha2 = git.resolve_commit(commit2)
  if not sha1 then
    return vim.notify("Gdc: invalid commit '" .. commit1 .. "'", vim.log.levels.ERROR)
  end
  if not sha2 then
    return vim.notify("Gdc: invalid commit '" .. commit2 .. "'", vim.log.levels.ERROR)
  end

  local earlier, later = order_by_time(sha1, sha2)
  local files = get_changed_files(earlier, later)
  if not files then
    return vim.notify("Gdc: failed to get diff", vim.log.levels.ERROR)
  end
  if #files == 0 then
    return vim.notify("Gdc: no changes between commits", vim.log.levels.WARN)
  end

  create_buffer(earlier, later, files)
end

-- Command registration

local function parse_args(args)
  local c1, c2 = args:match("^(%S+)%s+(%S+)$")
  if c1 and c2 then return c1, c2 end
  c1, c2 = args:match("^(%S+)%.%.(%S+)$")
  if c1 and c2 then return c1, c2 end
  return nil, nil
end

local function complete_refs(arglead)
  local branches = git.list_branches()
  table.insert(branches, "HEAD")
  table.insert(branches, "HEAD~1")
  table.insert(branches, "HEAD~5")
  if arglead and arglead ~= "" then
    local filtered = {}
    for _, b in ipairs(branches) do
      if b:find(arglead, 1, true) == 1 then
        table.insert(filtered, b)
      end
    end
    return filtered
  end
  return branches
end

local function command_handler(opts)
  local commit1, commit2 = parse_args(opts.args)
  if not commit1 or not commit2 then
    return vim.notify("Usage: :Gdc <commit1> <commit2>", vim.log.levels.ERROR)
  end
  gdc(commit1, commit2)
end

local command_opts = {
  nargs = "+",
  desc = "Compare two commits with Fugitive-style UI",
  complete = complete_refs,
}

vim.api.nvim_create_user_command("Gdc", command_handler, command_opts)
vim.api.nvim_create_user_command("GitDiffCommits", command_handler, command_opts)

-- GDiffBranch: Compare HEAD with a branch
-- NOTE: This is a simplified version that compares commits only (HEAD vs branch tip).
-- The original VimScript version compared working tree (dirty filesystem) against branch.
-- For full working tree support, see .dotfiles-543
local function gdiffbranch_handler(opts)
  local branch = opts.args
  if not branch or branch == "" then
    return vim.notify("Usage: :GDiffBranch <branch>", vim.log.levels.ERROR)
  end
  gdc("HEAD", branch)
end

vim.api.nvim_create_user_command("GDiffBranch", gdiffbranch_handler, {
  nargs = 1,
  desc = "Compare HEAD with a branch (commit-to-commit only, no working tree)",
  complete = complete_refs,
})

return { gdc = gdc }
