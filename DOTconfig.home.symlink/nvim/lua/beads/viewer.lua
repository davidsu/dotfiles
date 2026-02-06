-- Beads Viewer - nvim-tree style bead browser

local merger = require("beads.merger")

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
}

local state = {
  buf = nil,
  win = nil,
  beads = {},
  flat = {},
  expanded = {},
  cwd = nil,
  show_help = false,
  scoped_epic = nil,
  scoped_epic_bead = nil,
  status_filter = "open",
}

local help_lines = {
  "",
  " Keymaps",
  " ───────────────────────────",
  " Enter   expand epic / open details",
  " o       open bead details",
  " K       preview bead (floating)",
  " Tab     toggle expand/collapse",
  " BS      collapse epic",
  " C-]     drill into epic",
  " -       drill up (back to all)",
  " C-a     show all (open + closed)",
  " C-o     show open only",
  " C-c     show closed only",
  " r       refresh list",
  " q/Esc   close viewer",
  " g?      toggle this help",
  "",
  " Icons",
  " ───────────────────────────",
  " ▶ ▼     epic (collapsed/open)",
  " ○       task",
  " ●       bug",
  " ◆       feature",
  "",
  " Priority",
  " ───────────────────────────",
  " P0  critical (red)",
  " P1  high (yellow)",
  " P2  medium (blue)",
  " P3  low (cyan)",
  " P4  backlog (default)",
  "",
}

-- Helpers

local function runBd(subcmd)
  local cwd = state.cwd or vim.fn.getcwd()
  local cmd = string.format("cd %s && bd %s 2>/dev/null", vim.fn.shellescape(cwd), subcmd)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  return output
end

local function parseJson(output)
  if not output then return nil end
  local ok, data = pcall(vim.json.decode, output)
  return ok and data or nil
end

local function wipeBufferByName(pattern)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):find(pattern, 1, true) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

-- Data fetching

local function statusFlag()
  if state.status_filter == "all" then return " --status=all" end
  if state.status_filter == "closed" then return " --status=closed" end
  return ""
end

local function fetchBeads()
  local cwd = state.cwd or vim.fn.getcwd()
  if state.status_filter == "all" then
    return merger.fetchAllBeads(cwd)
  end
  local output = runBd("list --json" .. statusFlag())
  if not output then return nil, "Failed to run bd list" end
  local beads = parseJson(output)
  if not beads then return nil, "Failed to parse JSON" end
  return beads
end

local function fetchBeadDetails(id)
  return runBd(string.format("show %s", vim.fn.shellescape(id))) or ""
end

local function fetchChildren(parentId)
  local cwd = state.cwd or vim.fn.getcwd()
  if state.status_filter == "all" then
    local parent_flag = string.format(" --parent %s", vim.fn.shellescape(parentId))
    return merger.fetchAllBeads(cwd, parent_flag)
  end
  local output = runBd(string.format("list --parent %s --json%s", vim.fn.shellescape(parentId), statusFlag()))
  return parseJson(output) or {}
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
      local children = epic.children or {}
      table.sort(children, sortByPriorityThenTitle)
      for _, child in ipairs(children) do
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

local function applyHighlights()
  local ns = vim.api.nvim_create_namespace("beads_viewer")
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

  for i, item in ipairs(state.flat) do
    if item.bead then
      local line = i + (state.header_size or HEADER_LINES) - 1
      local hl = item.bead.status == "closed" and "Comment"
        or priority_highlight[item.bead.priority]
      if hl then
        vim.api.nvim_buf_add_highlight(state.buf, ns, hl, line, 0, -1)
      end
    end
  end
end

local function renderToBuffer()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  state.flat = buildFlatList(state.beads)

  local filter_label = state.status_filter == "all" and " [all]"
    or state.status_filter == "closed" and " [closed]"
    or ""
  local scope_label = state.scoped_epic_bead and (" > " .. (state.scoped_epic_bead.title or state.scoped_epic)) or ""
  local lines = { " Beads" .. filter_label .. scope_label, string.rep("─", WIDTH) }

  if state.show_help then
    vim.list_extend(lines, help_lines)
    table.insert(lines, string.rep("─", WIDTH))
  end

  if state.scoped_epic_bead then
    table.insert(lines, renderItem({ bead = state.scoped_epic_bead, depth = 0, is_epic = true }))
    table.insert(lines, string.rep("─", WIDTH))
  end

  state.header_size = #lines

  for _, item in ipairs(state.flat) do
    table.insert(lines, renderItem(item))
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  applyHighlights()
end

-- Window/Buffer management

local function isWindowOpen()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function closeViewer()
  if isWindowOpen() then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function createBuffer()
  wipeBufferByName("Beads")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "beads"
  vim.api.nvim_buf_set_name(buf, "Beads")
  return buf
end

local function createWindow(buf)
  local win = vim.api.nvim_open_win(buf, true, {
    split = "left",
    width = WIDTH,
  })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winfixwidth = true
  vim.wo[win].cursorline = true
  return win
end

-- Actions

local function findMainWindow()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= state.win then return win end
  end
  return state.win
end

local function getItemAtCursor()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local idx = line - (state.header_size or HEADER_LINES)
  return (idx > 0 and idx <= #state.flat) and state.flat[idx] or nil
end

local function showDetails()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local id = item.bead.id
  local bufname = "bead://" .. id
  local output = fetchBeadDetails(id)
  local lines = vim.split(output, "\n")

  local main_win = findMainWindow()
  local prev_buf = vim.api.nvim_win_get_buf(main_win)

  wipeBufferByName(bufname)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, bufname)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_win_set_buf(main_win, buf)
  vim.api.nvim_set_current_win(main_win)

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_buf_is_valid(prev_buf) then
      vim.api.nvim_win_set_buf(main_win, prev_buf)
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_set_current_win(state.win)
    end
  end, { buffer = buf })
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

local function showFloatingPreview()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local output = fetchBeadDetails(item.bead.id)
  local lines = vim.split(output, "\n")

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local float_width = editor_width - 4
  local float_height = editor_height - 4

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = float_width,
    height = float_height,
    col = (editor_width - float_width) / 2,
    row = (editor_height - float_height) / 2,
    style = "minimal",
    border = "rounded",
    title = " " .. item.bead.id .. " ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf })
  vim.keymap.set("n", "<Esc>", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf })
end

local function enterItem()
  local item = getItemAtCursor()
  if not item then return end
  if item.is_epic then
    toggleExpand()
  else
    showDetails()
  end
end

local function collapseEpic()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local id = item.is_epic and item.bead.id or nil
  if not id then return end

  if state.expanded[id] then
    state.expanded[id] = false
    renderToBuffer()
  end
end

local function toggleHelp()
  state.show_help = not state.show_help
  renderToBuffer()
end

local function clearChildrenCache()
  for _, bead in ipairs(state.beads) do
    bead.children = nil
  end
end

local function refetchExpandedChildren()
  for _, bead in ipairs(state.beads) do
    if state.expanded[bead.id] then
      bead.children = fetchChildren(bead.id)
    end
  end
end

local function restoreCursorTo(bead_id)
  if not bead_id or not state.win or not vim.api.nvim_win_is_valid(state.win) then return end
  for i, item in ipairs(state.flat) do
    if item.bead and item.bead.id == bead_id then
      local line = i + (state.header_size or HEADER_LINES)
      pcall(vim.api.nvim_win_set_cursor, state.win, { line, 0 })
      return
    end
  end
end

local function setFilter(filter)
  local item = getItemAtCursor()
  local current_bead_id = item and item.bead and item.bead.id

  state.status_filter = filter
  clearChildrenCache()
  local beads, err
  if state.scoped_epic then
    beads = fetchChildren(state.scoped_epic)
  else
    beads, err = fetchBeads()
  end
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  state.beads = beads
  refetchExpandedChildren()
  renderToBuffer()
  restoreCursorTo(current_bead_id)
end

local function drillInto()
  local item = getItemAtCursor()
  if not item or not item.is_epic then return end
  local epic_id = item.bead.id
  local epic_bead = item.bead
  state.scoped_epic = epic_id
  state.scoped_epic_bead = epic_bead
  clearChildrenCache()
  state.beads = fetchChildren(epic_id)
  state.expanded = {}
  renderToBuffer()
end

local function drillUp()
  if not state.scoped_epic then return end
  state.scoped_epic = nil
  state.scoped_epic_bead = nil
  clearChildrenCache()
  local beads, err = fetchBeads()
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  state.beads = beads
  renderToBuffer()
end

local function refresh()
  clearChildrenCache()
  local beads, err
  if state.scoped_epic then
    beads = fetchChildren(state.scoped_epic)
  else
    beads, err = fetchBeads()
  end
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
  vim.keymap.set("n", "<CR>", enterItem, opts)
  vim.keymap.set("n", "o", showDetails, opts)
  vim.keymap.set("n", "<Tab>", toggleExpand, opts)
  vim.keymap.set("n", "<BS>", collapseEpic, opts)
  vim.keymap.set("n", "<C-]>", drillInto, opts)
  vim.keymap.set("n", "-", drillUp, opts)
  vim.keymap.set("n", "<C-a>", function() setFilter("all") end, opts)
  vim.keymap.set("n", "<C-o>", function() setFilter("open") end, opts)
  vim.keymap.set("n", "<C-c>", function() setFilter("closed") end, opts)
  vim.keymap.set("n", "r", refresh, opts)
  vim.keymap.set("n", "q", closeViewer, opts)
  vim.keymap.set("n", "<Esc>", closeViewer, opts)
  vim.keymap.set("n", "g?", toggleHelp, opts)
  vim.keymap.set("n", "K", showFloatingPreview, opts)
end

-- Public API

local function open(opts)
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

local function toggle(opts)
  if isWindowOpen() then closeViewer() else open(opts) end
end

local function setup()
  vim.api.nvim_create_user_command("Beads", function(cmd)
    toggle({ cwd = cmd.args ~= "" and cmd.args or nil })
  end, { nargs = "?", desc = "Toggle Beads viewer" })

  vim.api.nvim_create_user_command("BeadsRefresh", refresh, { desc = "Refresh Beads viewer" })
end

return {
  open = open,
  toggle = toggle,
  setup = setup,
}
