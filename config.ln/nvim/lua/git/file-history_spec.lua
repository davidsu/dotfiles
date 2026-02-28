-- Tests for git/file-history.lua (GitFileHistory / Gfh command)
--
-- Run: :PlenaryBustedFile %

local eq = assert.are.same

-- Try to load fugitive if not already available
local fugitive_path = vim.fn.stdpath('data') .. '/lazy/vim-fugitive'
if vim.fn.isdirectory(fugitive_path) == 1 then
  vim.opt.rtp:prepend(fugitive_path)
  pcall(function() vim.cmd('runtime plugin/fugitive.vim') end)
end

local has_fugitive = vim.fn.exists(':Git') == 2

-- Test helpers for git repo management

local test_dir = nil

local function run_git(cmd)
  local output = vim.fn.system("cd " .. test_dir .. " && git " .. cmd .. " 2>&1")
  return output:gsub("%s+$", ""), vim.v.shell_error == 0
end

local function create_temp_git_repo()
  test_dir = vim.fn.tempname()
  vim.fn.mkdir(test_dir, "p")
  run_git("init")
  run_git("config user.email 'test@test.com'")
  run_git("config user.name 'Test User'")
  return test_dir
end

local commit_time = 1700000000

local function add_test_commit(filename, content, message)
  local filepath = test_dir .. "/" .. filename
  local file = io.open(filepath, "w")
  file:write(content)
  file:close()
  run_git("add " .. filename)
  commit_time = commit_time + 100
  local date_str = tostring(commit_time)
  local env = string.format("GIT_COMMITTER_DATE='%s' GIT_AUTHOR_DATE='%s'", date_str, date_str)
  vim.fn.system(string.format("cd %s && %s git commit -m '%s' 2>&1", test_dir, env, message or "Add " .. filename))
  local sha = run_git("rev-parse HEAD")
  return sha
end

local function cleanup_temp_repo()
  if test_dir then
    vim.fn.delete(test_dir, "rf")
    test_dir = nil
  end
end

local function get_buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function get_buffer_name()
  return vim.api.nvim_buf_get_name(0)
end

local function close_all_windows()
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  vim.cmd("enew")
  vim.t.pane_list_win = nil
  vim.t.pane_detail_wins = nil
end

-- Tests

describe("GitFileHistory", function()
  local original_dir
  local commit1, commit2, commit3

  before_each(function()
    close_all_windows()
    original_dir = vim.fn.getcwd()
    commit_time = 1700000000
    create_temp_git_repo()
    vim.cmd("cd " .. test_dir)

    commit1 = add_test_commit("test.lua", "version 1", "First commit")
    commit2 = add_test_commit("test.lua", "version 2", "Second commit")
    commit3 = add_test_commit("test.lua", "version 3", "Third commit")

    vim.cmd("edit " .. test_dir .. "/test.lua")
  end)

  after_each(function()
    close_all_windows()
    vim.cmd("cd " .. original_dir)
    cleanup_temp_repo()
  end)

  describe("command registration", function()
    it("registers :Gfh command", function()
      eq(2, vim.fn.exists(":Gfh"))
    end)

    it("registers :GitFileHistory command", function()
      eq(2, vim.fn.exists(":GitFileHistory"))
    end)
  end)

  describe("buffer content", function()
    it("shows commit log lines", function()
      vim.cmd("Gfh")
      local lines = get_buffer_lines()

      -- Should have 3 commits (one per line from git log --oneline)
      assert.is_true(#lines >= 3, "Expected at least 3 log lines, got " .. #lines)
    end)

    it("each line starts with a short SHA", function()
      vim.cmd("Gfh")
      local lines = get_buffer_lines()

      for _, line in ipairs(lines) do
        if line ~= "" then
          assert.truthy(line:match("^[a-f0-9]+"), "Expected SHA prefix in: " .. line)
        end
      end
    end)

    it("shows commit messages", function()
      vim.cmd("Gfh")
      local lines = get_buffer_lines()

      local found_third = false
      local found_second = false
      local found_first = false
      for _, line in ipairs(lines) do
        if line:match("Third commit") then found_third = true end
        if line:match("Second commit") then found_second = true end
        if line:match("First commit") then found_first = true end
      end
      assert.is_true(found_third, "Expected 'Third commit' in log")
      assert.is_true(found_second, "Expected 'Second commit' in log")
      assert.is_true(found_first, "Expected 'First commit' in log")
    end)

    it("most recent commit appears first", function()
      vim.cmd("Gfh")
      local lines = get_buffer_lines()

      assert.truthy(lines[1]:match("Third commit"), "Most recent commit should be first")
    end)
  end)

  describe("window management", function()
    it("creates list window and stores in tab variable", function()
      vim.cmd("Gfh")

      assert.truthy(vim.t.pane_list_win, "pane_list_win should be set")
      assert.is_true(vim.api.nvim_win_is_valid(vim.t.pane_list_win))
    end)

    it("list buffer is scratch (nofile, not swapped)", function()
      vim.cmd("Gfh")

      local list_buf = vim.api.nvim_win_get_buf(vim.t.pane_list_win)
      eq("nofile", vim.bo[list_buf].buftype)
      eq(false, vim.bo[list_buf].swapfile)
      eq("wipe", vim.bo[list_buf].bufhidden)
    end)

    it("list buffer name starts with gfh://", function()
      vim.cmd("Gfh")

      local list_buf = vim.api.nvim_win_get_buf(vim.t.pane_list_win)
      local buf_name = vim.api.nvim_buf_get_name(list_buf)
      assert.truthy(buf_name:match("^gfh://"), "Buffer name should start with gfh://, got: " .. buf_name)
    end)

    it("reuses existing list window on subsequent calls", function()
      vim.cmd("Gfh")
      local first_win = vim.t.pane_list_win

      vim.cmd("Gfh")
      local second_win = vim.t.pane_list_win

      eq(first_win, second_win)
    end)
  end)

  describe("keybinds", function()
    it("q closes the list window", function()
      vim.cmd("Gfh")
      assert.truthy(vim.t.pane_list_win)

      vim.api.nvim_feedkeys("q", "x", false)
      vim.wait(100)

      eq(1, #vim.api.nvim_tabpage_list_wins(0))
    end)

    it("g? shows help", function()
      vim.cmd("Gfh")

      local notified_help = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Gfh keymaps") then notified_help = true end
      end

      vim.api.nvim_feedkeys("g?", "x", false)
      vim.wait(100)

      vim.notify = original_notify
      assert.is_true(notified_help)
    end)
  end)

  describe("Enter key (on_select)", function()
    local test_fn = has_fugitive and it or pending
    test_fn("opens file at commit in detail pane", function()
      vim.cmd("Gfh")
      local list_win = vim.t.pane_list_win

      -- Cursor on first line (most recent commit)
      vim.api.nvim_win_set_cursor(list_win, { 1, 0 })

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      local windows = vim.api.nvim_tabpage_list_wins(0)
      eq(2, #windows)

      local detail_win = windows[1] == list_win and windows[2] or windows[1]
      local detail_buf = vim.api.nvim_win_get_buf(detail_win)
      local buf_name = vim.api.nvim_buf_get_name(detail_buf)
      assert.truthy(buf_name:match("fugitive://"), "Detail should show fugitive buffer, got: " .. buf_name)
    end)
  end)

  describe("dd keybind (diff view)", function()
    local test_fn = has_fugitive and it or pending
    test_fn("opens diff split for selected commit", function()
      vim.cmd("Gfh")
      local list_win = vim.t.pane_list_win

      -- Second line = second most recent commit (has a parent)
      vim.api.nvim_win_set_cursor(list_win, { 2, 0 })

      vim.api.nvim_feedkeys("dd", "x", false)
      vim.wait(200)

      local windows = vim.api.nvim_tabpage_list_wins(0)
      eq(3, #windows, "Expected 3 windows: list + 2 diff panes")

      local diff_wins = {}
      for _, win in ipairs(windows) do
        if win ~= list_win then
          table.insert(diff_wins, win)
        end
      end
      eq(2, #diff_wins, "Expected 2 diff windows")

      for _, win in ipairs(diff_wins) do
        assert.is_true(vim.wo[win].diff, "Diff window should have diff mode enabled")
      end
    end)
  end)

  describe("Ctrl-S keybind (commit details)", function()
    local test_fn = has_fugitive and it or pending
    test_fn("opens commit details in new tab", function()
      vim.cmd("Gfh")

      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-s>", true, false, true), "x", false)
      vim.wait(200)

      -- Should have opened a new tab
      local tabs = vim.api.nvim_list_tabpages()
      assert.is_true(#tabs >= 2, "Expected at least 2 tabs, got " .. #tabs)
    end)
  end)

  describe("error handling", function()
    it("shows error when not in git repo", function()
      local non_git_dir = vim.fn.tempname()
      vim.fn.mkdir(non_git_dir, "p")
      vim.cmd("cd " .. non_git_dir)
      vim.cmd("edit " .. non_git_dir .. "/somefile.txt")

      local notified_error = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("not in a git repository") then notified_error = true end
      end

      vim.cmd("Gfh")

      vim.notify = original_notify
      vim.fn.delete(non_git_dir, "rf")
      assert.is_true(notified_error)
    end)

    it("shows warning for file with no history", function()
      -- Create a new untracked file (no git history)
      local new_file = test_dir .. "/brand_new.txt"
      local file = io.open(new_file, "w")
      file:write("untracked")
      file:close()
      vim.cmd("edit " .. new_file)

      local notified_warn = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("no history found") then notified_warn = true end
      end

      vim.cmd("Gfh")

      vim.notify = original_notify
      assert.is_true(notified_warn)
    end)

    it("shows error when no file in buffer", function()
      vim.cmd("enew")

      local notified_error = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("no file specified") then notified_error = true end
      end

      vim.cmd("Gfh")

      vim.notify = original_notify
      assert.is_true(notified_error)
    end)
  end)

  describe("filepath argument", function()
    it("accepts explicit filepath argument", function()
      -- Add a second file with history
      add_test_commit("other.lua", "content", "Add other file")
      vim.cmd("Gfh " .. test_dir .. "/other.lua")

      local list_buf = vim.api.nvim_win_get_buf(vim.t.pane_list_win)
      local buf_name = vim.api.nvim_buf_get_name(list_buf)
      assert.truthy(buf_name:match("other.lua"), "Buffer name should contain other.lua, got: " .. buf_name)
    end)
  end)
end)
