package.loaded['config.fileline'] = nil
require('config.fileline').setup()

local function create_file_with_lines(count)
  local path = vim.fn.resolve(vim.fn.tempname()) .. '.lua'
  local lines = {}
  for i = 1, count do lines[i] = 'line ' .. i end
  vim.fn.writefile(lines, path)
  return path
end

local function type_command(cmd)
  vim.api.nvim_feedkeys(':' .. cmd .. '\r', 'tx', false)
  vim.wait(20)
end

local function count_buf_win_leaves()
  local count = { value = 0 }
  vim.api.nvim_create_autocmd('BufWinLeave', {
    group = vim.api.nvim_create_augroup('FileLineSpec', { clear = true }),
    callback = function() count.value = count.value + 1 end,
  })
  return count
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

  describe('typed :edit', function()
    it('jumps within the current file without the buffer leaving the window', function()
      vim.cmd.edit(vim.fn.fnameescape(path))
      local leaves = count_buf_win_leaves()
      type_command('e ' .. path .. ':7:3')
      assert.equals(0, leaves.value)
      assert.same({ 7, 2 }, vim.api.nvim_win_get_cursor(0))
    end)

    it('opens another file at the position', function()
      local other = create_file_with_lines(10)
      vim.cmd.edit(vim.fn.fnameescape(path))
      type_command('edit ' .. other .. ':5:2')
      assert.equals(other, vim.api.nvim_buf_get_name(0))
      assert.same({ 5, 1 }, vim.api.nvim_win_get_cursor(0))
    end)

    it('keeps the typed command in history', function()
      type_command('e ' .. path .. ':7:3')
      assert.equals('e ' .. path .. ':7:3', vim.fn.histget(':', -1))
    end)

    it('adds a jumplist entry like a count-G motion', function()
      vim.cmd.edit(vim.fn.fnameescape(path))
      type_command('e ' .. path .. ':7:3')
      vim.cmd('normal! \15')
      assert.same({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)
end)
