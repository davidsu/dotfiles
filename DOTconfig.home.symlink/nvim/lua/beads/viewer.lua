-- Beads Viewer - nvim-tree style bead browser

local M = {}

local HEADER_LINES = 2
local WIDTH = 40

local icons = {
  epic_open = "▼",
  epic_closed = "▶",
  task = "○",
  bug = "●",
  feature = "◆",
  open = " ",
  in_progress = " ",
  closed = " ",
}

local priority_highlight = {
  [0] = "DiagnosticError",
  [1] = "DiagnosticWarn",
  [2] = "DiagnosticInfo",
  [3] = "DiagnosticHint",
  [4] = "Comment",
}

local state = {
  buf = nil,
  win = nil,
  beads = {},
  flat = {},
  expanded = {},
  cwd = nil,
}

-- Data fetching

local function fetchBeads()
  local cwd = state.cwd or vim.fn.getcwd()
  local cmd = string.format("cd %s && bd list --json 2>/dev/null", vim.fn.shellescape(cwd))
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil, "Failed to run bd list"
  end

  local ok, beads = pcall(vim.json.decode, output)
  if not ok then
    return nil, "Failed to parse JSON"
  end

  return beads or {}
end

local function fetchBeadDetails(id)
  local cwd = state.cwd or vim.fn.getcwd()
  local cmd = string.format("cd %s && bd show %s 2>/dev/null", vim.fn.shellescape(cwd), vim.fn.shellescape(id))
  return vim.fn.system(cmd)
end

local function fetchChildren(parentId)
  local cwd = state.cwd or vim.fn.getcwd()
  local cmd = string.format("cd %s && bd list --parent %s --json 2>/dev/null", vim.fn.shellescape(cwd), vim.fn.shellescape(parentId))
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then return {} end

  local ok, children = pcall(vim.json.decode, output)
  return ok and children or {}
end

-- Tree building

local function sortByPriorityThenTitle(a, b)
  if a.priority ~= b.priority then
    return (a.priority or 99) < (b.priority or 99)
  end
  return (a.title or "") < (b.title or "")
end

local function isEpic(bead)
  return bead.issue_type == "epic"
end

local function buildFlatList(beads)
  local epics, tasks = {}, {}

  for _, bead in ipairs(beads) do
    table.insert(isEpic(bead) and epics or tasks, bead)
  end

  table.sort(epics, sortByPriorityThenTitle)
  table.sort(tasks, sortByPriorityThenTitle)

  local flat = {}

  for _, epic in ipairs(epics) do
    table.insert(flat, { bead = epic, depth = 0, is_epic = true })
    if state.expanded[epic.id] then
      for _, child in ipairs(epic.children or {}) do
        table.insert(flat, { bead = child, depth = 1, is_epic = false })
      end
    end
  end

  if #epics > 0 and #tasks > 0 then
    table.insert(flat, { separator = "─── Tasks ───" })
  end

  for _, task in ipairs(tasks) do
    table.insert(flat, { bead = task, depth = 0, is_epic = false })
  end

  return flat
end

-- Rendering

local function truncateTitle(title, maxLen)
  if #title <= maxLen then return title end
  return string.sub(title, 1, maxLen - 1) .. "…"
end

local function renderItem(item)
  if item.separator then return item.separator end

  local bead = item.bead
  local indent = string.rep("  ", item.depth)

  local icon = item.is_epic
    and (state.expanded[bead.id] and icons.epic_open or icons.epic_closed)
    or (icons[bead.issue_type] or icons.task)

  local status = icons[bead.status] or icons.open
  local priority = bead.priority and string.format("P%d", bead.priority) or ""
  local title = truncateTitle(bead.title or bead.id, WIDTH - #indent - 10)

  return string.format("%s%s %s %s %s", indent, icon, status, priority, title)
end

local function renderToBuffer()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  state.flat = buildFlatList(state.beads)

  local lines = { " Beads", string.rep("─", WIDTH) }
  for _, item in ipairs(state.flat) do
    table.insert(lines, renderItem(item))
  end

  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

  applyHighlights()
end

function applyHighlights()
  local ns = vim.api.nvim_create_namespace("beads_viewer")
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

  for i, item in ipairs(state.flat) do
    if item.bead and item.bead.priority then
      local hl = priority_highlight[item.bead.priority]
      if hl then
        vim.api.nvim_buf_add_highlight(state.buf, ns, hl, i + HEADER_LINES - 1, 0, -1)
      end
    end
  end
end

-- Window/Buffer management

local function isWindowOpen()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function closeViewer()
  if isWindowOpen() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

local function createBuffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "beads")
  pcall(vim.api.nvim_buf_set_name, buf, "Beads")  -- ignore if name exists
  return buf
end

local function createWindow(buf)
  vim.cmd("topleft vnew")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_width(win, WIDTH)

  local win_opts = { number = false, relativenumber = false, signcolumn = "no", winfixwidth = true, cursorline = true }
  for opt, val in pairs(win_opts) do
    vim.api.nvim_win_set_option(win, opt, val)
  end

  return win
end

-- Actions

local function getItemAtCursor()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local idx = line - HEADER_LINES
  return (idx > 0 and idx <= #state.flat) and state.flat[idx] or nil
end

local function toggleExpand()
  local item = getItemAtCursor()
  if not item or not item.is_epic then return end

  local id = item.bead.id
  local willExpand = not state.expanded[id]

  if willExpand and not item.bead.children then
    item.bead.children = fetchChildren(id)
  end

  state.expanded[id] = willExpand
  renderToBuffer()
end

local function showDetails()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local output = fetchBeadDetails(item.bead.id)
  local lines = vim.split(output, "\n")

  vim.cmd("botright vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "bead://" .. item.bead.id)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.keymap.set("n", "q", "<cmd>bdelete<CR>", { buffer = buf })
end

local function refresh()
  local beads, err = fetchBeads()
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  state.beads = beads
  renderToBuffer()
  vim.notify("Beads refreshed", vim.log.levels.INFO)
end

local function setupKeymaps(buf)
  local opts = { buffer = buf }
  vim.keymap.set("n", "<CR>", showDetails, opts)
  vim.keymap.set("n", "o", toggleExpand, opts)
  vim.keymap.set("n", "<Tab>", toggleExpand, opts)
  vim.keymap.set("n", "r", refresh, opts)
  vim.keymap.set("n", "q", closeViewer, opts)
  vim.keymap.set("n", "<Esc>", closeViewer, opts)
end

-- Public API

function M.open(opts)
  opts = opts or {}
  state.cwd = opts.cwd or vim.fn.getcwd()

  if isWindowOpen() then
    closeViewer()
    return
  end

  state.buf = createBuffer()
  state.win = createWindow(state.buf)
  setupKeymaps(state.buf)

  local beads, err = fetchBeads()
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    closeViewer()
    return
  end

  state.beads = beads
  renderToBuffer()
end

function M.toggle(opts)
  if isWindowOpen() then closeViewer() else M.open(opts) end
end

function M.setup()
  vim.api.nvim_create_user_command("Beads", function(cmd)
    M.toggle({ cwd = cmd.args ~= "" and cmd.args or nil })
  end, { nargs = "?", desc = "Toggle Beads viewer" })

  vim.api.nvim_create_user_command("BeadsRefresh", refresh, { desc = "Refresh Beads viewer" })
end

return M
