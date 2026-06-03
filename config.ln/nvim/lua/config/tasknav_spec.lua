-- Tests for config/tasknav.lua
-- Run with: :PlenaryBustedFile %

local nav = require('config.tasknav')._test
local eq = assert.are.equal

local function create_git_repo(path)
  vim.fn.mkdir(path, 'p')
  vim.fn.system('git -C ' .. path .. ' init -q')
end

local function write_file(path, line_count)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local lines = {}
  for i = 1, line_count do lines[i] = 'line ' .. i end
  vim.fn.writefile(lines, path)
end

local function set_line_and_cursor(text, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.api.nvim_win_set_cursor(0, { 1, col })
end

local function set_lines_and_cursor(lines, row, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { row, col })
end

describe('tasknav', function()
  describe('parseUrl', function()
    it('parses a single line ref', function()
      local path, line_start, line_end = nav.parseUrl('/src/app.tsx#L31')
      eq('src/app.tsx', path)
      eq(31, line_start)
      assert.is_nil(line_end)
    end)

    it('parses a line range', function()
      local path, line_start, line_end = nav.parseUrl('/src/app.tsx#L31-L71')
      eq('src/app.tsx', path)
      eq(31, line_start)
      eq(71, line_end)
    end)

    it('strips a ?plain=1 query', function()
      local path, line_start = nav.parseUrl('/notes/readme.md?plain=1#L14')
      eq('notes/readme.md', path)
      eq(14, line_start)
    end)

    it('returns nil when there is no line fragment', function()
      assert.is_nil(nav.parseUrl('/src/app.tsx'))
    end)
  end)

  describe('parseLinkUnderCursor', function()
    it('returns the ref when the cursor is on the link', function()
      set_line_and_cursor('see [label](/src/app.tsx#L10-L20) here', 8)
      local path, line_start, line_end = nav.parseLinkUnderCursor()
      eq('src/app.tsx', path)
      eq(10, line_start)
      eq(20, line_end)
    end)

    it('returns nil when the cursor is outside any link', function()
      set_line_and_cursor('see [label](/src/app.tsx#L10) here', 1)
      assert.is_nil(nav.parseLinkUnderCursor())
    end)

    local refs = {
      '| [reduceSandboxSlot][p1] does work |',
      '',
      '[p1]: /src/app.reducer.ts#L90-L99',
    }

    it('resolves a reference link from its label', function()
      set_lines_and_cursor(refs, 1, 4) -- on [reduceSandboxSlot]
      local path, line_start, line_end = nav.parseLinkUnderCursor()
      eq('src/app.reducer.ts', path)
      eq(90, line_start)
      eq(99, line_end)
    end)

    it('resolves a reference link from its [ref] key', function()
      set_lines_and_cursor(refs, 1, 23) -- on [p1]
      local path, line_start = nav.parseLinkUnderCursor()
      eq('src/app.reducer.ts', path)
      eq(90, line_start)
    end)

    it('returns nil for a reference with no definition', function()
      set_lines_and_cursor({ 'see [undefined][nope] here' }, 1, 6)
      assert.is_nil(nav.parseLinkUnderCursor())
    end)
  end)

  describe('resolveReference', function()
    it('finds a definition anywhere in the buffer', function()
      set_lines_and_cursor({ 'body', '[k]: /src/x.ts#L5' }, 1, 0)
      eq('/src/x.ts#L5', nav.resolveReference('k'))
    end)

    it('escapes magic characters in the ref label', function()
      set_lines_and_cursor({ '[a.b:c]: /src/x.ts#L5' }, 1, 0)
      eq('/src/x.ts#L5', nav.resolveReference('a.b:c'))
    end)

    it('returns nil when the ref is undefined', function()
      set_lines_and_cursor({ 'no defs here' }, 1, 0)
      assert.is_nil(nav.resolveReference('missing'))
    end)
  end)

  describe('openCodeLink', function()
    local test_dir

    before_each(function()
      test_dir = '/tmp/tasknav_spec_' .. os.time()
      create_git_repo(test_dir)
      write_file(test_dir .. '/src/target.tsx', 50)
      -- gitRoot resolves from the current buffer's dir, so start inside the repo
      write_file(test_dir .. '/suss-tasks/task.md', 1)
      vim.cmd.edit(test_dir .. '/suss-tasks/task.md')
    end)

    after_each(function()
      vim.cmd('silent! bwipeout!')
      vim.fn.delete(test_dir, 'rf')
    end)

    it('opens the target file at the start line', function()
      nav.openCodeLink('src/target.tsx', 25, nil)
      eq(25, vim.api.nvim_win_get_cursor(0)[1])
      assert.truthy(vim.api.nvim_buf_get_name(0):match('target%.tsx$'))
    end)

    it('positions the cursor at the start of a range', function()
      nav.openCodeLink('src/target.tsx', 10, 15)
      eq(10, vim.api.nvim_win_get_cursor(0)[1])
    end)

    it('notifies and stays put when the file is missing', function()
      local messages = {}
      local original_notify = vim.notify
      vim.notify = function(msg) messages[#messages + 1] = msg end

      nav.openCodeLink('src/does-not-exist.tsx', 1, nil)

      vim.notify = original_notify
      assert.truthy(messages[1]:match('file not found'))
    end)
  end)
end)
