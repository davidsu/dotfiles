-- Beads Viewer - nvim-tree style bead browser

local merger = require("beads.merger")
local editor = require("beads.editor")

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
  scoped_epic = nil,
  scoped_epic_bead = nil,
  status_filter = "open",
}

local help_keymaps = {
  { lhs = "<CR>",      desc = "expand epic / open details" },
  { lhs = "o",         desc = "open bead details" },
  { lhs = "K",         desc = "preview bead (floating)" },
  { lhs = "<Tab>",     desc = "toggle expand/collapse" },
  { lhs = "<BS>",      desc = "collapse epic" },
  { lhs = "<C-]>",     desc = "drill into epic" },
  { lhs = "-",         desc = "drill up (back to all)" },
  { lhs = "gy",        desc = "copy bead ID to clipboard" },
  { lhs = "<space>c",  desc = "close bead (epic: +children)" },
  { lhs = "<space>o",  desc = "(re)open bead" },
  { lhs = "<space>i",  desc = "mark in progress" },
  { lhs = "<space>d",  desc = "delete bead (epic: +children)" },
  { lhs = "<C-a>",     desc = "show all (open + closed)" },
  { lhs = "<C-o>",     desc = "show open only" },
  { lhs = "<C-c>",     desc = "show closed only" },
  { lhs = "r",         desc = "refresh list" },
  { lhs = "q",         desc = "close viewer" },
  { lhs = "g?",        desc = "search keymaps" },
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
      pcall(vim.api.nvim_clear_autocmds, { buffer = buf })
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

  if state.scoped_epic then
    return merger.fetchAllBeads(cwd)
  end

  -- Top-level view: use --no-parent to exclude child issues
  local output = runBd("list --json --no-parent --limit 0" .. statusFlag())
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
  local parent_flag = string.format(" --parent %s", vim.fn.shellescape(parentId))
  return merger.fetchAllBeads(cwd, parent_flag)
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
    if isEpic(bead) then
      table.insert(epics, bead)
    else
      table.insert(tasks, bead)
    end
  end

  table.sort(epics, sortByPriorityThenTitle)
  table.sort(tasks, sortByPriorityThenTitle)

  local flat = {}

  local function appendWithChildren(bead, depth)
    local epic = isEpic(bead)
    table.insert(flat, { bead = bead, depth = depth, is_epic = epic })
    if epic and state.expanded[bead.id] then
      if not bead.children then
        bead.children = fetchChildren(bead.id)
      end
      local children = bead.children or {}
      table.sort(children, sortByPriorityThenTitle)
      for _, child in ipairs(children) do
        appendWithChildren(child, depth + 1)
      end
    end
  end

  for _, epic in ipairs(epics) do
    appendWithChildren(epic, 0)
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

local function renderItem(item)
  if item.separator then return item.separator end

  local bead = item.bead
  local indent = string.rep("  ", item.depth)

  local icon = item.is_epic
    and (state.expanded[bead.id] and icons.epic_open or icons.epic_closed)
    or (icons[bead.issue_type] or icons.task)

  local status = icons[bead.status] or icons.open
  local priority = bead.priority and string.format("P%d", bead.priority) or ""
  local title = bead.title or bead.id

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
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then
      vim.cmd("enew")
    else
      vim.api.nvim_win_close(state.win, true)
    end
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
    win = -1,
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
    if win ~= state.win and vim.api.nvim_win_is_valid(win) then
      return win
    end
  end
  return vim.api.nvim_get_current_win()
end

local function getItemAtCursor()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local idx = line - (state.header_size or HEADER_LINES)
  return (idx > 0 and idx <= #state.flat) and state.flat[idx] or nil
end

local function gitRoot()
  local cwd = state.cwd or vim.fn.getcwd()
  local root = vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then return cwd end
  return vim.trim(root)
end

local function parseFileRef()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Match file_path:lineStart-lineEnd or file_path:line (path must contain / or .)
  for ref_start, path, suffix in line:gmatch("()([%w_%.%-/]+%.[%w]+)(:%d+%-?%d*)") do
    local ref_end = ref_start + #path + #suffix - 1
    if col >= ref_start and col <= ref_end then
      local line_start = tonumber(suffix:match(":(%d+)"))
      local line_end = tonumber(suffix:match("%-(%d+)"))
      return path, line_start, line_end
    end
  end
end

local function highlightRange(line_start, line_end)
  local ok, iw = pcall(require, "interestingwords")
  if not ok then return end

  iw.UncolorAllWords(false)

  local line_count = vim.api.nvim_buf_line_count(0)
  line_end = math.min(line_end, line_count)

  vim.api.nvim_win_set_cursor(0, { line_start, 0 })
  local range = line_end - line_start
  if range > 0 then
    vim.cmd("normal! V" .. range .. "j")
  else
    vim.cmd("normal! V")
  end
  iw.InterestingWord("v", false)
end

local function positionViewport(target_line)
  vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  vim.cmd("normal! zt")
  local quarter = math.floor(vim.api.nvim_win_get_height(0) / 4)
  if quarter > 0 then
    vim.cmd("normal! " .. quarter .. "\\<C-y>")
  end
end

local function openFileRef(path, line_start, line_end)
  local root = gitRoot()
  local abs_path = root .. "/" .. path
  if vim.fn.filereadable(abs_path) ~= 1 then
    vim.notify("File not found: " .. abs_path, vim.log.levels.WARN)
    return
  end

  local main_win = findMainWindow()
  if not main_win or not vim.api.nvim_win_is_valid(main_win) then
    vim.notify("Cannot find main window", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_win(main_win)
  vim.cmd.edit(vim.fn.fnameescape(abs_path))

  if line_start and line_end then
    highlightRange(line_start, line_end)
    positionViewport(line_start)
  elseif line_start then
    positionViewport(line_start)
  end
end

local function slugify(text)
  -- Strip leading # and whitespace
  text = text:gsub("^#+ *", "")
  -- Lowercase
  text = text:lower()
  -- Replace non-alphanumeric with hyphens
  text = text:gsub("[^%w]+", "-")
  -- Collapse consecutive hyphens
  text = text:gsub("%-+", "-")
  -- Trim leading/trailing hyphens
  text = text:gsub("^%-", ""):gsub("%-$", "")
  return text
end

local function findSectionLine(lines, section_slug)
  for i, l in ipairs(lines) do
    if l:match("^##+ ") then
      if slugify(l) == section_slug then
        return i
      end
    end
  end
  -- Partial match fallback: slug contains or is contained by heading slug
  for i, l in ipairs(lines) do
    if l:match("^##+ ") then
      local heading_slug = slugify(l)
      if heading_slug:find(section_slug, 1, true) or section_slug:find(heading_slug, 1, true) then
        return i
      end
    end
  end
end

local function parseBeadRef()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Match bead-id pattern (optional dot prefix, word chars, hyphens, dots)
  for ref_start, id, suffix in line:gmatch("()(%.?[%w][%w%-%.]+)(:%d+:?%d*)") do
    local ref_end = ref_start + #id + #suffix - 1
    if col >= ref_start and col <= ref_end then
      local ref_line = tonumber(suffix:match(":(%d+)"))
      return id, ref_line
    end
  end
  -- Match beadId#section-slug (e.g. apper-research-auth#key-findings)
  for ref_start, id, slug in line:gmatch("()(%.?[%w][%w%-%.]+)#([%w%-]+)") do
    local ref_end = ref_start + #id + 1 + #slug - 1
    if col >= ref_start and col <= ref_end then
      return id, nil, slug
    end
  end
  -- Fallback: match ID without line:col suffix or #section
  for ref_start, id in line:gmatch("()(%.?[%w][%w%-%.]+[%w])") do
    local ref_end = ref_start + #id - 1
    if col >= ref_start and col <= ref_end then
      return id
    end
  end
end

local function openBeadById(id, line_nr, section_slug)
  local output = fetchBeadDetails(id)
  if output == "" then
    vim.notify("Bead not found: " .. id, vim.log.levels.WARN)
    return
  end

  local lines = vim.split(output, "\n")

  local tmp_dir = "/tmp/beads"
  vim.fn.mkdir(tmp_dir, "p")
  local tmp_file = tmp_dir .. "/" .. id .. ".md"
  if vim.fn.filereadable(tmp_file) == 1 then
    local timestamp = os.date("%Y-%m-%d-%H-%M-%S")
    vim.fn.rename(tmp_file, (tmp_file:gsub("%.md$", "-" .. timestamp .. ".bak.md")))
  end
  vim.fn.writefile(lines, tmp_file)

  -- Resolve section slug to line number
  if section_slug and not line_nr then
    line_nr = findSectionLine(lines, section_slug)
  end

  -- Clear modified flag on any bead buffer before switching away
  local cur_win = vim.api.nvim_get_current_win()
  local in_bead_buf = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(cur_win)):find("/tmp/beads/", 1, true)
  local main_win = in_bead_buf and cur_win or findMainWindow()
  if not main_win or not vim.api.nvim_win_is_valid(main_win) then
    vim.notify("Cannot find main window", vim.log.levels.ERROR)
    return
  end

  local main_buf = vim.api.nvim_win_get_buf(main_win)
  if vim.api.nvim_buf_get_name(main_buf):find("/tmp/beads/", 1, true) then
    vim.bo[main_buf].modified = false
  end
  local prev_buf = main_buf

  -- Switch to main window first, then edit (avoids window wipe from bufhidden=wipe)
  vim.api.nvim_set_current_win(main_win)
  vim.cmd.edit(vim.fn.fnameescape(tmp_file))
  local buf = vim.api.nvim_get_current_buf()

  local cwd = state.cwd or vim.fn.getcwd()
  editor.setupEditableBuffer(buf, cwd, id, output)

  vim.keymap.set("n", "gd", function()
    local path, line_start, line_end = parseFileRef()
    if path then
      openFileRef(path, line_start, line_end)
      return
    end
    local ref_id, ref_line, ref_slug = parseBeadRef()
    if ref_id then openBeadById(ref_id, ref_line, ref_slug) end
  end, { buffer = buf })

  vim.keymap.set("n", "q", function()
    vim.bo[buf].modified = false
    if vim.api.nvim_buf_is_valid(prev_buf) then
      vim.api.nvim_win_set_buf(main_win, prev_buf)
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_set_current_win(state.win)
    end
  end, { buffer = buf })

  if line_nr then
    positionViewport(line_nr)
  end
end

local function showDetails()
  local item = getItemAtCursor()
  if not item or not item.bead then return end
  openBeadById(item.bead.id)
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
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local idx = line - (state.header_size or HEADER_LINES)
  if idx < 1 or idx > #state.flat then return end

  local item = state.flat[idx]
  if not item or not item.bead then return end

  -- If on an expanded epic, collapse it
  if item.is_epic and state.expanded[item.bead.id] then
    state.expanded[item.bead.id] = false
    renderToBuffer()
    return
  end

  -- Otherwise walk backwards to find the parent epic and collapse it
  for i = idx - 1, 1, -1 do
    local prev = state.flat[i]
    if prev and prev.is_epic and prev.depth < item.depth then
      state.expanded[prev.bead.id] = false
      renderToBuffer()
      vim.api.nvim_win_set_cursor(state.win, { i + (state.header_size or HEADER_LINES), 0 })
      return
    end
  end
end

local function showHelp()
  local entries = {}
  local lhs_by_line = {}
  for _, km in ipairs(help_keymaps) do
    local entry = string.format("%-12s %s", km.lhs, km.desc)
    table.insert(entries, entry)
    lhs_by_line[entry] = km.lhs
  end
  local win = state.win
  require("fzf-lua").fzf_exec(entries, {
    prompt = "Beads Keymaps> ",
    winopts = { height = 0.6, width = 0.5 },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then return end
        local lhs = lhs_by_line[selected[1]]
        if not lhs or not win or not vim.api.nvim_win_is_valid(win) then return end
        vim.api.nvim_set_current_win(win)
        local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
    },
  })
end

local function clearChildrenCache()
  for _, bead in ipairs(state.beads) do
    bead.children = nil
  end
end

local function reloadBeads()
  clearChildrenCache()
  local beads, err
  if state.scoped_epic then
    beads = fetchChildren(state.scoped_epic)
  else
    beads, err = fetchBeads()
  end
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return false
  end
  state.beads = beads
  renderToBuffer()
  return true
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
  if reloadBeads() then
    restoreCursorTo(current_bead_id)
  end
end

local function copyBeadId()
  local item = getItemAtCursor()
  if not item or not item.bead then return end
  vim.fn.setreg("+", item.bead.id)
  vim.notify("Copied: " .. item.bead.id, vim.log.levels.INFO)
end

local function collectDescendantIds(parentId)
  local children = fetchChildren(parentId)
  if not children then return {} end
  local ids = {}
  for _, child in ipairs(children) do
    table.insert(ids, child.id)
    if isEpic(child) then
      vim.list_extend(ids, collectDescendantIds(child.id))
    end
  end
  return ids
end

local function closeBeadRecursive()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local id = item.bead.id
  local title = item.bead.title or id
  local current_bead_id = id

  local ids_to_close = { id }
  if item.is_epic then
    vim.list_extend(ids_to_close, collectDescendantIds(id))
  end

  local shell_args = table.concat(vim.tbl_map(vim.fn.shellescape, ids_to_close), " ")
  local result = runBd("close " .. shell_args)
  if result then
    local count = #ids_to_close
    local msg = count > 1
      and string.format("closed %d beads (%s + descendants)", count, title)
      or string.format("closed: %s", title)
    vim.notify(msg, vim.log.levels.INFO)
    if reloadBeads() then
      restoreCursorTo(current_bead_id)
    end
  else
    vim.notify(string.format("Failed to close %s", title), vim.log.levels.ERROR)
  end
end

local function updateBeadStatus(status)
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local id = item.bead.id
  local title = item.bead.title or id
  local current_bead_id = id

  local result = runBd(string.format("update %s --status=%s", vim.fn.shellescape(id), status))
  if result then
    vim.notify(string.format("%s: %s", status, title), vim.log.levels.INFO)
    if reloadBeads() then
      restoreCursorTo(current_bead_id)
    end
  else
    vim.notify(string.format("Failed to update %s", title), vim.log.levels.ERROR)
  end
end

local function deleteBead()
  local item = getItemAtCursor()
  if not item or not item.bead then return end

  local id = item.bead.id
  local title = item.bead.title or id

  local function doDelete(cascade)
    local flag = cascade and " --cascade --force" or " --force"
    local result = runBd(string.format("delete %s%s", vim.fn.shellescape(id), flag))
    if result then
      vim.notify("Deleted: " .. title, vim.log.levels.INFO)
      reloadBeads()
    else
      vim.notify("Failed to delete: " .. title, vim.log.levels.ERROR)
    end
  end

  if item.is_epic then
    local ok = vim.fn.confirm(
      string.format("Delete epic '%s' and ALL its children?", title),
      "&Yes\n&No", 2
    )
    if ok == 1 then doDelete(true) end
  else
    local ok = vim.fn.confirm(
      string.format("Delete '%s'?", title),
      "&Yes\n&No", 2
    )
    if ok == 1 then doDelete(false) end
  end
end

local function drillInto()
  local item = getItemAtCursor()
  if not item or not item.is_epic then return end
  state.scoped_epic = item.bead.id
  state.scoped_epic_bead = item.bead
  state.expanded = {}
  reloadBeads()
end

local function drillUp()
  if not state.scoped_epic then return end
  state.scoped_epic = nil
  state.scoped_epic_bead = nil
  reloadBeads()
end

local function refresh()
  if reloadBeads() then
    vim.notify("Beads refreshed", vim.log.levels.INFO)
  end
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
  vim.keymap.set("n", "gy", copyBeadId, opts)
  vim.keymap.set("n", "<space>c", closeBeadRecursive, opts)
  vim.keymap.set("n", "<space>o", function() updateBeadStatus("open") end, opts)
  vim.keymap.set("n", "<space>i", function() updateBeadStatus("in_progress") end, opts)
  vim.keymap.set("n", "<space>d", deleteBead, opts)
  vim.keymap.set("n", "r", refresh, opts)
  vim.keymap.set("n", "q", closeViewer, opts)
  vim.keymap.set("n", "<Esc>", closeViewer, opts)
  vim.keymap.set("n", "g?", showHelp, opts)
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

  -- Save cursor on focus loss so :only or external close doesn't lose position
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    buffer = state.buf,
    callback = function()
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        state.saved_cursor = vim.api.nvim_win_get_cursor(state.win)
      end
    end,
  })

  if not reloadBeads() then
    closeViewer()
    return
  end

  if state.saved_cursor then
    local max_line = vim.api.nvim_buf_line_count(state.buf)
    local row = math.min(state.saved_cursor[1], max_line)
    pcall(vim.api.nvim_win_set_cursor, state.win, { row, state.saved_cursor[2] })
  end
end

local function toggle(opts)
  if isWindowOpen() then closeViewer() else open(opts) end
end

local function findBeadInViewer(bead_id)
  if not bead_id then return end

  if not isWindowOpen() then
    open()
  end
  if not state.beads then return end

  -- Check if bead is a direct child of an epic - expand that epic
  for _, epic in ipairs(state.beads) do
    if isEpic(epic) then
      if not epic.children then
        epic.children = fetchChildren(epic.id)
      end
      for _, child in ipairs(epic.children or {}) do
        if child.id == bead_id then
          state.expanded[epic.id] = true
          renderToBuffer()
          restoreCursorTo(bead_id)
          return
        end
      end
    end
  end

  -- Bead might be top-level
  restoreCursorTo(bead_id)
end

local function findCurrentBead()
  local name = vim.api.nvim_buf_get_name(0)
  local bead_id = name:match("/tmp/beads/(.+)%.md$")
  if not bead_id then
    vim.notify("Not in a bead buffer", vim.log.levels.WARN)
    return
  end
  findBeadInViewer(bead_id)
end

local function setup()
  vim.api.nvim_create_user_command("Beads", function(cmd)
    local arg = cmd.args and vim.trim(cmd.args) or ""
    arg = arg ~= "" and arg or nil
    if arg and not arg:find("/") then
      open()
      openBeadById(arg)
    else
      toggle({ cwd = arg })
    end
  end, { nargs = "?", desc = "Toggle Beads viewer or open a bead by ID" })

  vim.api.nvim_create_user_command("BeadsRefresh", refresh, { desc = "Refresh Beads viewer" })
  vim.api.nvim_create_user_command("BeadsFind", findCurrentBead, { desc = "Find current bead in viewer" })
end

return {
  open = open,
  toggle = toggle,
  find = findCurrentBead,
  setup = setup,
  _test = {
    parseFileRef = parseFileRef,
    parseBeadRef = parseBeadRef,
    openFileRef = openFileRef,
    highlightRange = highlightRange,
    positionViewport = positionViewport,
    slugify = slugify,
    findSectionLine = findSectionLine,
    gitRoot = gitRoot,
    state = state,
  },
}
