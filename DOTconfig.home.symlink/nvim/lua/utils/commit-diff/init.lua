-- Fugitive-style UI for comparing two arbitrary commits
-- Usage: :Gdc <commit1> <commit2> or :Gdc <commit1>..<commit2>

local git = require("utils.commit-diff.git")
local ui = require("utils.commit-diff.ui")

local function gdc(commit1, commit2)
  if not git.in_repo() then
    return vim.notify("Gdc: not in a git repository", vim.log.levels.ERROR)
  end

  local sha1 = git.resolve_commit(commit1)
  local sha2 = git.resolve_commit(commit2)
  if not sha1 then
    return vim.notify("Gdc: invalid commit '" .. commit1 .. "'", vim.log.levels.ERROR)
  end
  if not sha2 then
    return vim.notify("Gdc: invalid commit '" .. commit2 .. "'", vim.log.levels.ERROR)
  end

  local earlier, later = git.order_by_time(sha1, sha2)

  local files = git.get_changed_files(earlier, later)
  if not files then
    return vim.notify("Gdc: failed to get diff", vim.log.levels.ERROR)
  end
  if #files == 0 then
    return vim.notify("Gdc: no changes between commits", vim.log.levels.WARN)
  end

  ui.create_buffer(earlier, later, files)
end

-- Parse "commit1 commit2" or "commit1..commit2"
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
    local branches = git.list_branches()
    table.insert(branches, "HEAD")
    table.insert(branches, "HEAD~1")
    table.insert(branches, "HEAD~5")
    return branches
  end,
})

return { gdc = gdc }
