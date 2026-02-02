-- Compare two commits with Fugitive-style UI
-- Usage: :Gdc <commit1> [commit2] (defaults to HEAD)

local git = require("git.helpers")
local panes = require("panes")

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

local function parse_file_line(line)
  local status, path = line:match("^(.) (.+)$")
  return status, path
end

local function get_commit_for_status(status, earlier, later)
  return (status == "-") and earlier or later
end

local function close_all()
  panes.close_all_details()
  panes.close_list_window()
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

local function build_on_select(earlier, later)
  return function(line)
    local status, filepath = parse_file_line(line)
    if not filepath then return nil end

    local commit = get_commit_for_status(status, earlier, later)
    local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. commit .. "/" .. filepath

    -- Create buffer without changing current window
    local bufnr = vim.fn.bufadd(fugitive_path)
    vim.fn.bufload(bufnr)
    vim.bo[bufnr].buftype = "nowrite"

    return bufnr
  end
end

local function build_keymaps(earlier, later)
  return {
    {
      key = "dd",
      fn = function(line)
        local status, filepath = parse_file_line(line)
        if not filepath then return end
        git.show_diff(later, earlier, filepath)
      end
    },
    {
      key = "o",
      fn = function(line)
        local status, filepath = parse_file_line(line)
        if filepath then
          git.open_split(get_commit_for_status(status, earlier, later), filepath)
        end
      end
    },
    { key = "q", fn = function() close_all() end },
    { key = "g?", fn = function() show_help() end },
  }
end

local function create_buffer(earlier, later, files)
  local lines = {
    string.format("Comparing: %s → %s", earlier:sub(1, 8), later:sub(1, 8)),
    string.format("Files changed: %d", #files),
    "",
  }
  for _, file in ipairs(files) do
    table.insert(lines, format_status(file.status) .. " " .. file.path)
  end

  panes.show_list({
    lines = lines,
    name = string.format("gdc://%s..%s", earlier:sub(1, 8), later:sub(1, 8)),
    syntax = setup_syntax,
    cursor = { 4, 0 },
    on_select = build_on_select(earlier, later),
    keymaps = build_keymaps(earlier, later),
  })
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

local function parse_commits(args)
  local first_commit, second_commit = args:match("^(%S+)%s+(%S+)$")
  if first_commit and second_commit then
    return first_commit, second_commit
  end

  first_commit, second_commit = args:match("^(%S+)%.%.(%S+)$")
  if first_commit and second_commit then
    return first_commit, second_commit
  end

  first_commit = args:match("^(%S+)$")
  if first_commit then
    return first_commit, "HEAD"
  end

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
  local commit1, commit2 = parse_commits(opts.args)
  if not commit1 or not commit2 then
    return vim.notify("Usage: :Gdc <commit1> [commit2] (defaults to HEAD)", vim.log.levels.ERROR)
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
