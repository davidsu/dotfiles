-- Tests for config/mru.lua
-- Run with: :PlenaryBustedFile %

local mru_file = vim.fn.expand('~/.local/share/nvim_mru.txt')
require('config.mru').setup()

local function create_git_repo(path)
  vim.fn.mkdir(path, 'p')
  vim.fn.system('git -C ' .. path .. ' init -q')
  vim.fn.system('git -C ' .. path .. ' config user.email test@test.com')
  vim.fn.system('git -C ' .. path .. ' config user.name "Test"')
end

local function create_file(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = assert(io.open(path, 'w'))
  f:write('-- test\n')
  f:close()
end

local function first_mru_entry()
  if vim.fn.filereadable(mru_file) ~= 1 then return nil end
  for line in io.lines(mru_file) do return line end
end

local function new_mru_entries(marker)
  if vim.fn.filereadable(mru_file) ~= 1 then return {} end
  local entries = {}
  for line in io.lines(mru_file) do
    if marker and line == marker then break end
    entries[#entries + 1] = line
  end
  return entries
end

local function entry_path(entry)
  return entry:match('^(.+):%d+:%d+$')
end

local function commit_file(repo, relpath)
  create_file(repo .. '/' .. relpath)
  vim.fn.system('git -C ' .. repo .. ' add ' .. relpath)
  vim.fn.system('git -C ' .. repo .. ' commit -qm "add ' .. relpath .. '"')
end

local function create_worktree(main_repo, worktree_path)
  vim.fn.system('git -C ' .. main_repo .. ' worktree add -q ' .. worktree_path)
end

local test_dir

describe('mru', function()
  before_each(function()
    test_dir = '/tmp/mru_spec_' .. os.time()
    create_git_repo(test_dir)
  end)

  after_each(function()
    vim.cmd('silent! bwipeout!')
    vim.fn.delete(test_dir, 'rf')
  end)

  it('writes exactly one valid entry for a deeply nested file in a non-worktree repo', function()
    local filepath = test_dir .. '/backend/app/preview/service.lua'
    create_file(filepath)

    local marker = first_mru_entry()
    vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
    local new = new_mru_entries(marker)

    assert.equals(1, #new)
    local path = entry_path(new[1])
    assert.equals(1, vim.fn.filereadable(path), 'path does not exist on disk: ' .. tostring(path))
  end)

  it('does not accumulate duplicate main-repo entries when a worktree file is saved multiple times', function()
    local worktree = test_dir .. '_wt'
    commit_file(test_dir, 'src/deep/service.lua')
    create_worktree(test_dir, worktree)

    local wt_filepath = worktree .. '/src/deep/service.lua'
    local mru = require('config.mru')

    local marker = first_mru_entry()
    vim.cmd('edit ' .. vim.fn.fnameescape(wt_filepath))
    mru.save_mru(vim.api.nvim_get_current_buf(), true)  -- simulate a second save (e.g. BufLeave)

    local new = new_mru_entries(marker)

    -- should have exactly 2: worktree path + main-repo path, no duplicates
    assert.equals(2, #new)
    for _, entry in ipairs(new) do
      local path = entry_path(entry)
      assert.equals(1, vim.fn.filereadable(path), 'path does not exist on disk: ' .. tostring(path))
    end

    vim.fn.delete(worktree, 'rf')
  end)
end)
