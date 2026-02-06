-- Beads merger - queries all statuses and deduplicates

local function runBd(cwd, subcmd)
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

local function fetchAllBeads(cwd, parent_flag)
  local statuses = { "open", "in_progress", "blocked", "deferred", "closed" }
  local seen = {}
  local all_beads = {}

  for _, status in ipairs(statuses) do
    local subcmd = string.format("list --json --status=%s%s", status, parent_flag or "")
    local output = runBd(cwd, subcmd)
    local beads = parseJson(output)

    if beads then
      for _, bead in ipairs(beads) do
        if not seen[bead.id] then
          seen[bead.id] = true
          table.insert(all_beads, bead)
        end
      end
    end
  end

  return all_beads
end

return {
  fetchAllBeads = fetchAllBeads,
}
