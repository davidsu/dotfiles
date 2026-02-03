-- Tests for git/commit-diff.lua (GitDiffCommits / Gdc command)
--
-- Run all tests (including fugitive-dependent ones):
--   :PlenaryBustedFile % {minimal_init = 'lua/git/test_init.lua'}
--
-- Run without plugins (skips fugitive tests):
--   :PlenaryBustedFile %

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

local commit_time = 1700000000  -- Starting timestamp

local function add_test_commit(filename, content, message)
  local filepath = test_dir .. "/" .. filename
  local file = io.open(filepath, "w")
  file:write(content)
  file:close()
  run_git("add " .. filename)
  -- Use explicit timestamps to ensure correct ordering (no race conditions)
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
  -- Clear panes state from previous test
  vim.t.pane_list_win = nil
  vim.t.pane_detail_wins = nil
end

-- Tests

describe("GitDiffCommits", function()
  local original_dir
  local commit1, commit2, commit3

  before_each(function()
    close_all_windows()
    original_dir = vim.fn.getcwd()
    commit_time = 1700000000  -- Reset timestamp for each test
    create_temp_git_repo()
    vim.cmd("cd " .. test_dir)

    -- Create test commits with incrementing timestamps
    commit1 = add_test_commit("file1.txt", "initial content", "First commit")
    commit2 = add_test_commit("file2.txt", "second file", "Second commit")
    commit3 = add_test_commit("file1.txt", "modified content", "Third commit")

    -- Open a file so we have a proper buffer (needed for splits to work)
    vim.cmd("edit " .. test_dir .. "/file1.txt")
  end)

  after_each(function()
    close_all_windows()
    vim.cmd("cd " .. original_dir)
    cleanup_temp_repo()
  end)

  describe("command parsing", function()
    it("accepts two space-separated commits", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))
      local name = get_buffer_name()
      assert.truthy(name:match("gdc://"))
    end)

    it("accepts dot notation (commit1..commit2)", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. ".." .. commit2:sub(1, 8))
      local name = get_buffer_name()
      assert.truthy(name:match("gdc://"))
    end)

    it("defaults second commit to HEAD when only one given", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8))
      local lines = get_buffer_lines()
      -- Should compare commit1 to HEAD (commit3)
      assert.truthy(lines[1]:match("Comparing:"))
    end)

    it("shows error for invalid commit", function()
      local notified = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("invalid commit") then notified = true end
      end

      vim.cmd("Gdc invalidcommit HEAD")

      vim.notify = original_notify
      assert.is_true(notified)
    end)
  end)

  describe("buffer content", function()
    it("shows header with commit range", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))
      local lines = get_buffer_lines()
      assert.truthy(lines[1]:match("Comparing:"))
      assert.truthy(lines[1]:match(commit1:sub(1, 8)))
    end)

    it("shows file count", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))
      local lines = get_buffer_lines()
      assert.truthy(lines[2]:match("Files changed:"))
    end)

    it("lists changed files with status indicators", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))
      local lines = get_buffer_lines()
      -- file2.txt was added in commit2, should show as "+ file2.txt"
      local found_added_file = false
      for _, line in ipairs(lines) do
        if line:match("^%+ file2%.txt") then
          found_added_file = true
          break
        end
      end
      assert.is_true(found_added_file, "Expected to find '+ file2.txt' in buffer")
    end)

    it("shows M for modified files", function()
      vim.cmd("Gdc " .. commit2:sub(1, 8) .. " " .. commit3:sub(1, 8))
      local lines = get_buffer_lines()
      local found_modified = false
      for _, line in ipairs(lines) do
        if line:match("file1.txt") then
          found_modified = true
          assert.truthy(line:match("^M"))
        end
      end
      assert.is_true(found_modified)
    end)
  end)

  describe("window management", function()
    it("creates list window and stores in tab variable", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      -- List window should be created and stored
      assert.truthy(vim.t.pane_list_win, "pane_list_win should be set")
      assert.is_true(vim.api.nvim_win_is_valid(vim.t.pane_list_win))

      -- Focus should be on list window
      eq(vim.api.nvim_get_current_win(), vim.t.pane_list_win)
    end)

    it("list window contains Gdc buffer with correct content", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      local list_win = vim.t.pane_list_win
      local list_buf = vim.api.nvim_win_get_buf(list_win)
      local lines = vim.api.nvim_buf_get_lines(list_buf, 0, 3, false)

      assert.truthy(lines[1]:match("Comparing:"), "First line should show 'Comparing:'")
      assert.truthy(lines[2]:match("Files changed:"), "Second line should show file count")
    end)

    it("list buffer is scratch (nofile, not swapped)", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      local list_buf = vim.api.nvim_win_get_buf(vim.t.pane_list_win)

      eq("nofile", vim.bo[list_buf].buftype)
      eq(false, vim.bo[list_buf].swapfile)
      eq("wipe", vim.bo[list_buf].bufhidden)
    end)

    it("reuses existing list window on subsequent Gdc calls", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))
      local first_list_win = vim.t.pane_list_win
      local first_buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(first_list_win))

      vim.cmd("Gdc " .. commit2:sub(1, 8) .. " " .. commit3:sub(1, 8))
      local second_list_win = vim.t.pane_list_win
      local second_buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(second_list_win))

      -- Same window reused
      eq(first_list_win, second_list_win)
      -- But buffer content changed (different commits in name)
      assert.are_not.equal(first_buf_name, second_buf_name)
    end)

    it("list buffer has correct name format", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      local list_buf = vim.api.nvim_win_get_buf(vim.t.pane_list_win)
      local buf_name = vim.api.nvim_buf_get_name(list_buf)

      -- Name format: gdc://earlier..later
      assert.truthy(buf_name:match("^gdc://"), "Buffer name should start with gdc://")
      assert.truthy(buf_name:match("%.%."), "Buffer name should contain '..'")
    end)
  end)

  describe("keybinds", function()
    it("q closes the list window and returns to original buffer", function()
      local original_buf = vim.api.nvim_get_current_buf()
      local original_win = vim.api.nvim_get_current_win()

      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      -- Should now have 2 windows
      eq(2, #vim.api.nvim_tabpage_list_wins(0))

      -- Press q
      vim.api.nvim_feedkeys("q", "x", false)
      vim.wait(100)

      -- Should be back to 1 window with original buffer
      eq(1, #vim.api.nvim_tabpage_list_wins(0))
      eq(original_buf, vim.api.nvim_get_current_buf())
    end)

    it("maps g? to show help", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      local notified_help = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Gdc keymaps") then notified_help = true end
      end

      vim.api.nvim_feedkeys("g?", "x", false)
      vim.wait(100)

      vim.notify = original_notify
      assert.is_true(notified_help)
    end)
  end)

  describe("Enter key (on_select)", function()
    -- Requires fugitive: on_select calls FugitiveGitDir() to build fugitive:// URLs
    local test_fn = has_fugitive and it or pending
    test_fn("opens file preview in detail pane", function()
      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit2:sub(1, 8))

      -- Move to a file line (line 4 is first file after header)
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      local list_win = vim.t.pane_list_win

      -- Press Enter
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Should have 2 windows: list + detail
      local windows = vim.api.nvim_tabpage_list_wins(0)
      eq(2, #windows)

      -- Detail window should have a fugitive buffer
      local detail_win = windows[1] == list_win and windows[2] or windows[1]
      local detail_buf = vim.api.nvim_win_get_buf(detail_win)
      local buf_name = vim.api.nvim_buf_get_name(detail_buf)
      assert.truthy(buf_name:match("fugitive://"), "Detail should show fugitive buffer")
    end)
  end)

  describe("dd keybind (diff view)", function()
    -- Requires fugitive: show_diff calls Gedit and Gvdiffsplit commands
    local test_fn = has_fugitive and it or pending
    test_fn("opens diff split for modified file", function()
      vim.cmd("Gdc " .. commit2:sub(1, 8) .. " " .. commit3:sub(1, 8))

      -- Move to file1.txt line (modified file)
      local lines = get_buffer_lines()
      local file_line = nil
      for i, line in ipairs(lines) do
        if line:match("file1.txt") then
          file_line = i
          break
        end
      end
      assert.truthy(file_line, "Should find file1.txt in buffer")

      vim.api.nvim_win_set_cursor(0, { file_line, 0 })

      local list_win = vim.t.pane_list_win

      -- Press dd
      vim.api.nvim_feedkeys("dd", "x", false)
      vim.wait(200)

      -- Should have 3 windows: list (top) + 2 diff windows (bottom)
      local windows = vim.api.nvim_tabpage_list_wins(0)
      eq(3, #windows, "Expected 3 windows: list + 2 diff panes")

      -- Find the two diff windows (not the list window)
      local diff_wins = {}
      for _, win in ipairs(windows) do
        if win ~= list_win then
          table.insert(diff_wins, win)
        end
      end
      eq(2, #diff_wins, "Expected 2 diff windows")

      -- Both diff windows should be in diff mode
      for _, win in ipairs(diff_wins) do
        assert.is_true(vim.wo[win].diff, "Diff window should have diff mode enabled")
      end
    end)
  end)

  describe("error handling", function()
    it("shows error when not in git repo", function()
      -- Move to a non-git directory
      local non_git_dir = vim.fn.tempname()
      vim.fn.mkdir(non_git_dir, "p")
      vim.cmd("cd " .. non_git_dir)

      local notified_error = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("not in a git repository") then notified_error = true end
      end

      vim.cmd("Gdc HEAD HEAD~1")

      vim.notify = original_notify
      vim.fn.delete(non_git_dir, "rf")
      assert.is_true(notified_error)
    end)

    it("shows error for no changes between identical commits", function()
      local notified_warn = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("no changes between commits") then notified_warn = true end
      end

      vim.cmd("Gdc " .. commit1:sub(1, 8) .. " " .. commit1:sub(1, 8))

      vim.notify = original_notify
      assert.is_true(notified_warn)
    end)
  end)

  describe("commit ordering", function()
    it("orders commits by timestamp (earlier first)", function()
      -- Pass commits in reverse chronological order
      vim.cmd("Gdc " .. commit2:sub(1, 8) .. " " .. commit1:sub(1, 8))
      local lines = get_buffer_lines()

      -- The header should show earlier -> later order
      -- commit1 is earlier than commit2
      local header = lines[1]
      local first_sha = header:match("Comparing: (%x+)")
      eq(commit1:sub(1, 8), first_sha)
    end)
  end)
end)

describe("GDiffBranch", function()
  local original_dir
  local main_commit

  before_each(function()
    close_all_windows()
    original_dir = vim.fn.getcwd()
    commit_time = 1700000000  -- Reset timestamp for each test
    create_temp_git_repo()
    vim.cmd("cd " .. test_dir)

    main_commit = add_test_commit("main.txt", "main content", "Main commit")
    run_git("checkout -b feature")
    add_test_commit("feature.txt", "feature content", "Feature commit")
  end)

  after_each(function()
    close_all_windows()
    vim.cmd("cd " .. original_dir)
    cleanup_temp_repo()
  end)

  it("compares HEAD with specified branch", function()
    vim.cmd("GDiffBranch master")
    local lines = get_buffer_lines()
    assert.truthy(lines[1]:match("Comparing:"))

    -- Should show feature.txt as added
    local found_feature = false
    for _, line in ipairs(lines) do
      if line:match("feature.txt") then
        found_feature = true
      end
    end
    assert.is_true(found_feature)
  end)
end)
