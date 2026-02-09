-- Show files changed in the commit that last modified the current line
-- Usage: g? in normal mode on any file in a git repo

local git = require("git.helpers")
local panes = require("panes")

-- Run git in a specific directory (for when cwd differs from file's repo)

local function run_in(dir, cmd)
  local output = vim.fn.system(
    string.format("git -C %s %s 2>/dev/null", vim.fn.shellescape(dir), cmd)
  )
  return output:gsub("%s+$", ""), vim.v.shell_error == 0
end

-- Git helpers

local function get_blame_sha(dir, filepath, line_nr)
  local output, ok = run_in(dir,
    string.format("blame -p -L %d,%d -- %s", line_nr, line_nr, vim.fn.shellescape(filepath))
  )
  if not ok then return nil end
  local sha = output:match("^(%x+)")
  if not sha or sha:match("^0+$") then return nil end
  return sha
end

local function get_commit_subject(dir, sha)
  local output, ok = run_in(dir, string.format("log -1 --format=%%s %s", sha))
  return ok and output or ""
end

local function get_file_list(dir, sha)
  local output, ok = run_in(dir, string.format("show --name-status --pretty=format: %s", sha))
  if not ok then return nil end

  local lines = {}
  for line in output:gmatch("[^\n]+") do
    if line ~= "" then
      table.insert(lines, line)
    end
  end
  return lines
end

local function resolve_sha(dir, sha)
  local output, ok = run_in(dir, "rev-parse " .. sha)
  return ok and output or sha
end

-- UI: Syntax highlighting

local function setup_syntax(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[
      if exists("b:current_syntax") | finish | endif

      syn match bsHeader /^Blame:.*$/
      syn match bsCount /^Files changed:.*$/
      syn match bsModified /^M\t/ nextgroup=bsPath
      syn match bsAdded /^A\t/ nextgroup=bsPath
      syn match bsDeleted /^D\t/ nextgroup=bsPath
      syn match bsRenamed /^R[0-9]*\t/ nextgroup=bsPath
      syn match bsPath /.*$/ contained

      hi def link bsHeader Label
      hi def link bsCount Number
      hi def link bsModified Type
      hi def link bsAdded DiffAdd
      hi def link bsDeleted DiffDelete
      hi def link bsRenamed Special
      hi def link bsPath Normal

      let b:current_syntax = "blame_show"
    ]])
  end)
end

-- UI: Line parsing

local function parse_file_line(line)
  local status, path = line:match("^(%a+)%s+(.+)$")
  return status, path
end

-- Main function

local function blame_show()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    return vim.notify("g?: no file", vim.log.levels.ERROR)
  end

  local dir = vim.fn.fnamemodify(filepath, ":h")
  local line_nr = vim.api.nvim_win_get_cursor(0)[1]
  local sha = get_blame_sha(dir, filepath, line_nr)
  if not sha then
    return vim.notify("g?: no commit (uncommitted line?)", vim.log.levels.WARN)
  end

  local full_sha = resolve_sha(dir, sha)
  local subject = get_commit_subject(dir, sha)
  local file_lines = get_file_list(dir, sha)
  if not file_lines or #file_lines == 0 then
    return vim.notify("g?: no files changed in commit", vim.log.levels.WARN)
  end

  local lines = {
    string.format("Blame: %s %s", sha:sub(1, 8), subject),
    string.format("Files changed: %d", #file_lines),
    "",
  }
  for _, fl in ipairs(file_lines) do
    table.insert(lines, fl)
  end

  vim.cmd("tabnew")
  vim.cmd("tcd " .. vim.fn.fnameescape(dir))

  panes.show_list({
    lines = lines,
    name = "blame://" .. sha:sub(1, 8),
    syntax = setup_syntax,
    cursor = { 4, 0 },
    use_current_window = true,
    on_select = function(line)
      local _, path = parse_file_line(line)
      if not path then return nil end

      local fugitive_path = "fugitive://" .. vim.fn.FugitiveGitDir() .. "//" .. full_sha .. "/" .. path
      local bufnr = vim.fn.bufadd(fugitive_path)
      vim.fn.bufload(bufnr)
      vim.bo[bufnr].buftype = "nowrite"
      return bufnr
    end,
    keymaps = {
      {
        key = "dd",
        fn = function(line)
          local _, path = parse_file_line(line)
          if not path then return end
          git.show_diff(full_sha, full_sha .. "^", path)
        end,
      },
    },
  })
end

-- Keymap registration

vim.keymap.set('n', 'g?', blame_show, { desc = 'Git: Blame show commit files' })

return { blame_show = blame_show }
