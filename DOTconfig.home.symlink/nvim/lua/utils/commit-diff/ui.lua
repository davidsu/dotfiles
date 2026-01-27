-- UI components for commit-diff: buffer, syntax, keymaps, actions

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

-- Actions
local function open_diff(earlier, later)
  local status, filepath = parse_file_line()
  if not filepath then return end

  local list_win = vim.api.nvim_get_current_win()
  close_diff_windows()
  vim.cmd("below split")

  if status == "+" then
    vim.cmd("Gedit " .. later .. ":" .. filepath)
  elseif status == "-" then
    vim.cmd("Gedit " .. earlier .. ":" .. filepath)
  else
    vim.cmd("Gedit " .. later .. ":" .. filepath)
    vim.cmd("Gvdiffsplit " .. earlier .. ":" .. filepath)
  end

  vim.api.nvim_set_current_win(list_win)
end

local function open_file(earlier, later)
  local status, filepath = parse_file_line()
  if not filepath then return end
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

-- Keymaps
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

-- Buffer creation
local function format_status(status)
  local icons = { M = "M", A = "+", D = "-", R = "R", C = "C" }
  return icons[status] or status
end

local function create_buffer(earlier, later, files)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

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

return {
  create_buffer = create_buffer,
}
