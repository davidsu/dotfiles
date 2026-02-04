-- Compare commits or working tree with Fugitive-style UI
-- Usage: :Gdc <commit>           (compare commit to working tree)
--        :Gdc <commit1> <commit2> (compare two commits)

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
  local cmd = later
    and string.format("diff --name-status %s %s", earlier, later)
    or string.format("diff --name-status %s", earlier)
  local output, ok = git.run(cmd)
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

local function get_git_root()
  local root, ok = git.run("rev-parse --show-toplevel")
  return ok and root or nil
end

local function build_on_select(earlier, later)
  return function(line)
    local status, filepath = parse_file_line(line)
    if not filepath then return nil end

    -- Working tree mode: open actual file for non-deleted files
    if not later then
      if status == "-" then
        -- Deleted file: show from commit
        local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. earlier .. "/" .. filepath
        local bufnr = vim.fn.bufadd(fugitive_path)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].buftype = "nowrite"
        return bufnr
      else
        -- Modified/added: open working tree file
        local git_root = get_git_root()
        local full_path = git_root and (git_root .. "/" .. filepath) or filepath
        local bufnr = vim.fn.bufadd(full_path)
        vim.fn.bufload(bufnr)
        return bufnr
      end
    end

    -- Commit-to-commit mode: use fugitive path
    local commit = get_commit_for_status(status, earlier, later)
    local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. commit .. "/" .. filepath

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
        if later then
          git.show_diff(later, earlier, filepath)
        else
          git.show_worktree_diff(earlier, filepath)
        end
      end
    },
    {
      key = "o",
      fn = function(line)
        local status, filepath = parse_file_line(line)
        if not filepath then return end
        if later then
          git.open_split(get_commit_for_status(status, earlier, later), filepath)
        else
          -- Working tree mode: open actual file in split
          local git_root = get_git_root()
          local full_path = git_root and (git_root .. "/" .. filepath) or filepath
          vim.cmd("split " .. full_path)
        end
      end
    },
    { key = "q", fn = function() close_all() end },
    { key = "g?", fn = function() show_help() end },
  }
end

local function create_buffer(earlier, later, files)
  local later_label = later and later:sub(1, 8) or "WORKTREE"
  local lines = {
    string.format("Comparing: %s → %s", earlier:sub(1, 8), later_label),
    string.format("Files changed: %d", #files),
    "",
  }
  for _, file in ipairs(files) do
    table.insert(lines, format_status(file.status) .. " " .. file.path)
  end

  panes.show_list({
    lines = lines,
    name = string.format("gdc://%s..%s", earlier:sub(1, 8), later_label),
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
  if not sha1 then
    return vim.notify("Gdc: invalid commit '" .. commit1 .. "'", vim.log.levels.ERROR)
  end

  -- Working tree mode: commit2 is nil
  local sha2 = commit2 and git.resolve_commit(commit2) or nil
  if commit2 and not sha2 then
    return vim.notify("Gdc: invalid commit '" .. commit2 .. "'", vim.log.levels.ERROR)
  end

  local earlier, later
  if sha2 then
    earlier, later = order_by_time(sha1, sha2)
  else
    -- Working tree mode: commit is "earlier", working tree is "later"
    earlier, later = sha1, nil
  end

  local files = get_changed_files(earlier, later)
  if not files then
    return vim.notify("Gdc: failed to get diff", vim.log.levels.ERROR)
  end
  if #files == 0 then
    local target = later and "commits" or "commit and working tree"
    return vim.notify("Gdc: no changes between " .. target, vim.log.levels.WARN)
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
    return first_commit, nil  -- Single arg: compare to working tree
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
  if not commit1 then
    return vim.notify("Usage: :Gdc <commit> [commit2] (defaults to working tree)", vim.log.levels.ERROR)
  end
  gdc(commit1, commit2)
end

local command_opts = {
  nargs = "+",
  desc = "Compare commit to working tree, or two commits",
  complete = complete_refs,
}

vim.api.nvim_create_user_command("Gdc", command_handler, command_opts)
vim.api.nvim_create_user_command("GitDiffCommits", command_handler, command_opts)

-- GDiffBranch: Alias for Gdc (muscle memory)
vim.api.nvim_create_user_command("GDiffBranch", command_handler, command_opts)

return { gdc = gdc }
