-- Fugitive-style UI for comparing two arbitrary commits
-- Usage: :Gdc <commit1> <commit2>

-- Git helpers
local function git(cmd)
  local output = vim.fn.system("git " .. cmd .. " 2>/dev/null")
  local success = vim.v.shell_error == 0
  return output:gsub("%s+$", ""), success
end

local function resolve_commit(ref)
  local sha, ok = git("rev-parse " .. ref)
  return ok and sha or nil
end

local function get_commit_timestamp(ref)
  local ts = git("log -1 --format=%ct " .. ref)
  return tonumber(ts) or 0
end

local function order_by_time(ref1, ref2)
  if get_commit_timestamp(ref1) < get_commit_timestamp(ref2) then
    return ref1, ref2
  end
  return ref2, ref1
end

local function get_changed_files(earlier, later)
  local output, ok = git(string.format("diff --name-status %s %s", earlier, later))
  if not ok then
    return nil
  end

  local files = {}
  for line in output:gmatch("[^\n]+") do
    local status, path = line:match("^(%a)%s+(.+)$")
    if status and path then
      table.insert(files, { status = status, path = path })
    end
  end
  return files
end

-- Syntax highlighting (Fugitive-style)
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

-- Window management
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

local function parse_file_line()
  local line = vim.api.nvim_get_current_line()
  local status, path = line:match("^(.) (.+)$")
  return status, path
end

-- Diff actions
local function open_diff(earlier, later)
  local status, filepath = parse_file_line()
  if not filepath then return end

  local list_win = vim.api.nvim_get_current_win()
  close_diff_windows()
  vim.cmd("below split")

  -- Handle added/deleted files (no diff, just show the file)
  if status == "+" then
    vim.cmd("Gedit " .. later .. ":" .. filepath)
  elseif status == "-" then
    vim.cmd("Gedit " .. earlier .. ":" .. filepath)
  else
    -- Modified: show diff between commits
    vim.cmd("Gedit " .. later .. ":" .. filepath)
    vim.cmd("Gvdiffsplit " .. earlier .. ":" .. filepath)
  end

  vim.api.nvim_set_current_win(list_win)
end

local function open_file(earlier, later)
  local status, filepath = parse_file_line()
  if not filepath then return end
  -- For deleted files, open at earlier commit; otherwise at later
  local commit = (status == "-") and earlier or later
  vim.cmd("Gedit " .. commit .. ":" .. filepath)
end

local function open_split(earlier, later)
  local status, filepath = parse_file_line()
  if not filepath then return end
  local commit = (status == "-") and earlier or later
  vim.cmd("Gsplit " .. commit .. ":" .. filepath)
end

local function close_all()
  close_diff_windows()
  vim.cmd("bdelete")
end

local function show_help()
  vim.notify(
    "Gdc keymaps:\n  dd    Diff split (M) or view file (+/-)\n  <CR>  Open file\n  o     Horizontal split\n  q     Close all",
    vim.log.levels.INFO
  )
end

-- Buffer setup
local function setup_keymaps(bufnr, earlier, later)
  local map = function(key, fn)
    vim.keymap.set("n", key, fn, { buffer = bufnr, silent = true })
  end

  map("dd", function() open_diff(earlier, later) end)
  map("<CR>", function() open_file(earlier, later) end)
  map("o", function() open_split(earlier, later) end)
  map("q", close_all)
  map("g?", show_help)
end

local function format_status(status)
  local icons = { M = "M", A = "+", D = "-", R = "R", C = "C" }
  return icons[status] or status
end

local function create_buffer(earlier, later, files)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)

  -- Buffer options
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

  -- Content
  local lines = {
    string.format("Comparing: %s → %s", earlier:sub(1, 8), later:sub(1, 8)),
    string.format("Files changed: %d", #files),
    "",
  }
  for _, file in ipairs(files) do
    table.insert(lines, format_status(file.status) .. " " .. file.path)
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  vim.api.nvim_buf_set_name(bufnr, string.format("gdc://%s..%s", earlier:sub(1, 8), later:sub(1, 8)))

  setup_syntax(bufnr)
  setup_keymaps(bufnr, earlier, later)

  vim.api.nvim_win_set_cursor(0, { 4, 0 })
end

-- Main entry point
local function gdc(commit1, commit2)
  -- Validate git repo
  local _, in_repo = git("rev-parse --git-dir")
  if not in_repo then
    return vim.notify("Gdc: not in a git repository", vim.log.levels.ERROR)
  end

  -- Validate and resolve commits
  local sha1 = resolve_commit(commit1)
  local sha2 = resolve_commit(commit2)
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

-- Parse arguments: supports "commit1 commit2" or "commit1..commit2"
local function parse_args(fargs)
  if #fargs == 2 then
    return fargs[1], fargs[2]
  end
  if #fargs == 1 then
    local c1, c2 = fargs[1]:match("^(.+)%.%.(.+)$")
    if c1 and c2 then
      return c1, c2
    end
  end
  return nil, nil
end

-- Command registration
vim.api.nvim_create_user_command("Gdc", function(opts)
  local commit1, commit2 = parse_args(opts.fargs)
  if not commit1 or not commit2 then
    return vim.notify("Usage: :Gdc <commit1>..<commit2> or :Gdc <commit1> <commit2>", vim.log.levels.ERROR)
  end
  gdc(commit1, commit2)
end, {
  nargs = "+",
  desc = "Compare two commits with Fugitive-style UI",
  complete = function()
    local branches = git("branch --format='%(refname:short)'")
    local completions = {}
    for branch in branches:gmatch("[^\n]+") do
      table.insert(completions, branch)
    end
    table.insert(completions, "HEAD")
    table.insert(completions, "HEAD~1")
    table.insert(completions, "HEAD~5")
    return completions
  end,
})

return { gdc = gdc }
