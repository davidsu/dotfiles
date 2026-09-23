package.loaded['config.fileline'] = nil
require('config.fileline').setup()

local function create_file_with_lines(count)
  local path = vim.fn.resolve(vim.fn.tempname()) .. '.lua'
  local lines = {}
  for i = 1, count do lines[i] = 'line ' .. i end
  vim.fn.writefile(lines, path)
  return path
end

local function edit(spec)
  vim.cmd('edit ' .. vim.fn.fnameescape(spec))
  return vim.api.nvim_buf_get_name(0), vim.api.nvim_win_get_cursor(0)
end

describe('fileline', function()
  local path

  before_each(function()
    path = create_file_with_lines(10)
  end)

  after_each(function()
    vim.cmd('silent! %bwipeout!')
  end)

  it('opens file:line:col at that position', function()
    local name, cursor = edit(path .. ':7:3')
    assert.equals(path, name)
    assert.same({ 7, 2 }, cursor)
  end)

  it('opens file:line at column 1', function()
    local name, cursor = edit(path .. ':4')
    assert.equals(path, name)
    assert.same({ 4, 0 }, cursor)
  end)

  it('clamps a line past the end of the file', function()
    local _, cursor = edit(path .. ':500:2')
    assert.same({ 10, 1 }, cursor)
  end)

  it('wipes the bogus buffer', function()
    edit(path .. ':7:3')
    assert.equals(0, vim.fn.bufexists(path .. ':7:3'))
  end)

  it('detects the filetype of the real file', function()
    edit(path .. ':1:1')
    assert.equals('lua', vim.bo.filetype)
  end)

  it('leaves a nonexistent path with a numeric suffix alone', function()
    local name = edit(path .. '.missing:7:3')
    assert.equals(path .. '.missing:7:3', name)
  end)

  it('leaves a plain nonexistent file alone', function()
    local missing = vim.fn.resolve(vim.fn.tempname())
    local name = edit(missing)
    assert.equals(missing, name)
  end)
end)
