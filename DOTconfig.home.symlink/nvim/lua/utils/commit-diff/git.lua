-- Git operations for commit-diff

local function run(cmd)
  local output = vim.fn.system("git " .. cmd .. " 2>/dev/null")
  local success = vim.v.shell_error == 0
  return output:gsub("%s+$", ""), success
end

local function resolve_commit(ref)
  local sha, ok = run("rev-parse " .. ref)
  return ok and sha or nil
end

local function get_timestamp(ref)
  local ts = run("log -1 --format=%ct " .. ref)
  return tonumber(ts) or 0
end

local function order_by_time(ref1, ref2)
  if get_timestamp(ref1) < get_timestamp(ref2) then
    return ref1, ref2
  end
  return ref2, ref1
end

local function get_changed_files(earlier, later)
  local output, ok = run(string.format("diff --name-status %s %s", earlier, later))
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

local function in_repo()
  local _, ok = run("rev-parse --git-dir")
  return ok
end

local function list_branches()
  local output = run("branch --format='%(refname:short)'")
  local branches = {}
  for branch in output:gmatch("[^\n]+") do
    table.insert(branches, branch)
  end
  return branches
end

return {
  resolve_commit = resolve_commit,
  order_by_time = order_by_time,
  get_changed_files = get_changed_files,
  in_repo = in_repo,
  list_branches = list_branches,
}
