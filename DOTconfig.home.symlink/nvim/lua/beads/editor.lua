-- Beads Editor - in-place editing with confirmation

local function runBd(cwd, subcmd)
  local cmd = string.format("cd %s && bd %s 2>/dev/null", vim.fn.shellescape(cwd), subcmd)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  return output
end

local function extractSection(lines, section_name)
  local in_section = false
  local section_lines = {}

  for _, line in ipairs(lines) do
    if line:match("^" .. section_name .. "$") then
      in_section = true
    elseif in_section and line:match("^[A-Z][A-Z_]+$") then
      in_section = false
    elseif in_section then
      table.insert(section_lines, line)
    end
  end

  -- trim leading/trailing empty lines (padding between header and content)
  while #section_lines > 0 and section_lines[1] == "" do
    table.remove(section_lines, 1)
  end
  while #section_lines > 0 and section_lines[#section_lines] == "" do
    table.remove(section_lines)
  end

  return table.concat(section_lines, "\n")
end

local function extractField(first_line, pattern)
  local match = first_line:match(pattern)
  return match and vim.trim(match) or nil
end

local function parseBeadShow(text)
  local lines = vim.split(text, "\n")
  local first_line = lines[1] or ""

  return {
    title = extractField(first_line, "·%s+(.-)%s+%["),
    description = extractSection(lines, "DESCRIPTION"),
    notes = extractSection(lines, "NOTES"),
  }
end

local function diffFields(before, after)
  local changes = {}

  if before.title ~= after.title then
    table.insert(changes, {
      field = "title",
      before = before.title or "",
      after = after.title or "",
    })
  end

  if before.description ~= after.description then
    table.insert(changes, {
      field = "description",
      before = before.description or "",
      after = after.description or "",
    })
  end

  if before.notes ~= after.notes then
    table.insert(changes, {
      field = "notes",
      before = before.notes or "",
      after = after.notes or "",
    })
  end

  return changes
end

local function applyUpdate(cwd, id, changes)
  for _, change in ipairs(changes) do
    local flag = change.field == "title" and "--title"
      or change.field == "description" and "--description"
      or change.field == "notes" and "--notes"

    if flag then
      local value = change.after:gsub("'", "'\\''")
      local cmd = string.format("update %s %s '%s'", vim.fn.shellescape(id), flag, value)
      runBd(cwd, cmd)
    end
  end
end

local function saveBeadBuffer(buf, cwd, bead_id, original_text)
  local current_text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

  local before = parseBeadShow(original_text)
  local after = parseBeadShow(current_text)
  local changes = diffFields(before, after)

  if #changes == 0 then
    vim.notify("No changes detected", vim.log.levels.INFO)
    return
  end

  applyUpdate(cwd, bead_id, changes)
  vim.notify("Bead updated: " .. bead_id, vim.log.levels.INFO)
  vim.bo[buf].modified = false
end

local function setupEditableBuffer(buf, cwd, bead_id, original_text)
  vim.bo[buf].modifiable = true

  for _, m in ipairs(vim.fn.getmatches()) do
    if m.group == "BeadsCloseReason" then vim.fn.matchdelete(m.id) end
  end
  vim.fn.matchadd("BeadsCloseReason", "^Close reason:.*$")

  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = buf,
    callback = function() saveBeadBuffer(buf, cwd, bead_id, original_text) end,
  })
end

return {
  setupEditableBuffer = setupEditableBuffer,
}
