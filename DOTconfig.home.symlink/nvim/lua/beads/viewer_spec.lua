-- Tests for beads/viewer.lua
--
-- Run: cd ~/.dotfiles/DOTconfig.home.symlink/nvim && nvim --headless -c "PlenaryBustedDirectory lua" -c "qa"


local eq = assert.are.same

-- Test helpers

local test_dir = nil
local original_cwd = nil

local function run_bd(cmd)
  local full_cmd = string.format("cd %s && bd %s 2>&1", test_dir, cmd)
  local output = vim.fn.system(full_cmd)
  return output:gsub("%s+$", ""), vim.v.shell_error == 0
end

local function create_test_repo()
  test_dir = "/tmp/beads-viewer-test-" .. os.time()
  if vim.fn.isdirectory(test_dir) == 1 then
    vim.fn.delete(test_dir, "rf")
  end
  vim.fn.mkdir(test_dir, "p")

  vim.fn.system(string.format("cd %s && git init && git config user.email 'test@test.com' && git config user.name 'Test'", test_dir))

  run_bd("init")

  return test_dir
end

local function cleanup_test_repo()
  if test_dir then
    vim.fn.delete(test_dir, "rf")
    test_dir = nil
  end
end

local function close_all_windows()
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  vim.cmd("enew")
  vim.t.pane_list_win = nil
  vim.t.pane_detail_wins = nil
end

local function create_test_beads()
  -- Epic with children
  run_bd("create 'Epic One' --type epic --priority 1 --silent")
  local epic1_id = vim.trim(vim.fn.system(string.format("cd %s && bd list --json 2>/dev/null | jq -r '.[0].id'", test_dir)))

  run_bd(string.format("create 'Task under epic' --type task --priority 2 --parent %s --silent", epic1_id))
  run_bd(string.format("create 'Bug under epic' --type bug --priority 0 --parent %s --silent", epic1_id))

  -- Empty epic
  run_bd("create 'Empty Epic' --type epic --priority 2 --silent")

  -- Standalone tasks
  run_bd("create 'Standalone task' --type task --priority 1 --silent")
  run_bd("create 'Another task' --type task --priority 3 --silent")

  -- Closed bead
  run_bd("create 'Closed task' --type task --priority 2 --silent")
  local closed_id = vim.trim(vim.fn.system(string.format("cd %s && bd list --json 2>/dev/null | jq -r '.[] | select(.title == \"Closed task\") | .id'", test_dir)))
  run_bd(string.format("close %s", closed_id))
end

-- Tests

describe("Beads Viewer", function()
  before_each(function()
    close_all_windows()
    original_cwd = vim.fn.getcwd()
    create_test_repo()
    create_test_beads()
    vim.cmd("cd " .. test_dir)

    package.loaded["beads.viewer"] = nil
    package.loaded["beads.merger"] = nil
    vim.loader.reset()
    require("beads.viewer").setup()
  end)

  after_each(function()
    close_all_windows()
    if original_cwd then
      vim.cmd("cd " .. original_cwd)
    end
    cleanup_test_repo()
  end)

  describe("open and close", function()
    it("creates viewer window and buffer", function()
      vim.cmd("Beads")

      local wins = vim.api.nvim_tabpage_list_wins(0)
      eq(2, #wins, "Should have 2 windows: beads + main")

      local beads_buf = vim.api.nvim_win_get_buf(wins[1])
      local buf_name = vim.api.nvim_buf_get_name(beads_buf)
      assert.truthy(buf_name:match("Beads$"))
    end)

    it("toggles closed without E95 buffer name error", function()
      vim.cmd("Beads")
      vim.cmd("Beads")  -- close

      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should have 1 window after close")

      vim.cmd("Beads")  -- reopen - should not error
      eq(2, #vim.api.nvim_tabpage_list_wins(0), "Should reopen without error")
    end)

    it("wipes buffer on close", function()
      vim.cmd("Beads")
      local beads_buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])

      vim.cmd("Beads")  -- close

      assert.is_false(vim.api.nvim_buf_is_valid(beads_buf), "Buffer should be wiped")
    end)
  end)

  describe("rendering", function()
    it("shows header with title", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 2, false)

      assert.truthy(lines[1]:match("Beads"), "Should show 'Beads' in header")
      assert.truthy(lines[2]:match("─"), "Should show separator")
    end)

    it("lists epics before tasks with separator", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local epic_line = nil
      local task_line = nil
      local separator_line = nil

      for i, line in ipairs(lines) do
        if line:match("Epic One") then epic_line = i end
        if line:match("Standalone task") then task_line = i end
        if line:match("─── Tasks ───") then separator_line = i end
      end

      assert.truthy(epic_line, "Should show epic")
      assert.truthy(task_line, "Should show task")
      assert.truthy(separator_line, "Should show separator")
      assert.is_true(epic_line < separator_line, "Epic should be before separator")
      assert.is_true(separator_line < task_line, "Separator should be before tasks")
    end)

    it("shows correct icons for types", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local epic_line = nil
      local task_line = nil

      for _, line in ipairs(lines) do
        if line:match("Epic One") then epic_line = line end
        if line:match("Standalone task") then task_line = line end
      end

      assert.truthy(epic_line:match("▶"), "Epic should show ▶")
      assert.truthy(task_line:match("○"), "Task should show ○")
    end)

    it("shows priority labels", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_p1 = false
      local found_p3 = false

      for _, line in ipairs(lines) do
        if line:match("P1") then found_p1 = true end
        if line:match("P3") then found_p3 = true end
      end

      assert.is_true(found_p1, "Should show P1 priority (epic/standalone task)")
      assert.is_true(found_p3, "Should show P3 priority (Another task)")
    end)

    it("hides children from top-level Tasks section", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_child_task = false
      local found_child_bug = false
      local found_standalone = false

      for _, line in ipairs(lines) do
        if line:match("Task under epic") then found_child_task = true end
        if line:match("Bug under epic") then found_child_bug = true end
        if line:match("Standalone task") then found_standalone = true end
      end

      assert.is_false(found_child_task, "Child task should not appear at top level")
      assert.is_false(found_child_bug, "Child bug should not appear at top level")
      assert.is_true(found_standalone, "Standalone task should still appear")
    end)
  end)

  describe("epic expansion", function()
    it("expands epic with Enter to show children", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      -- Find epic line
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      assert.truthy(epic_line_num, "Should find epic")

      -- Move to epic
      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })

      -- Press Enter
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Check for children
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_child = false
      for _, line in ipairs(lines) do
        if line:match("Task under epic") or line:match("Bug under epic") then
          found_child = true
          break
        end
      end

      assert.is_true(found_child, "Should show epic children after expand")
    end)

    it("changes icon from ▶ to ▼ when expanded", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          assert.truthy(line:match("▶"), "Should show ▶ when collapsed")
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for _, line in ipairs(lines) do
        if line:match("Epic One") then
          assert.truthy(line:match("▼"), "Should show ▼ when expanded")
          break
        end
      end
    end)

    pending("collapses epic with Enter again", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })

      -- Expand
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Re-find epic line after expand (buffer re-rendered)
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") and line:match("▼") then
          epic_line_num = i
          break
        end
      end
      assert.truthy(epic_line_num, "Should find expanded epic")
      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })

      -- Collapse
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(200)

      -- Re-fetch buffer from window in case it changed
      buf = vim.api.nvim_win_get_buf(win)
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_child = false
      for _, line in ipairs(lines) do
        if line:match("Task under epic") then
          found_child = true
          break
        end
      end

      assert.is_false(found_child, "Children should be hidden after collapse")
    end)

    it("indents children under epic", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for _, line in ipairs(lines) do
        if line:match("Task under epic") then
          assert.truthy(line:match("^  "), "Child should be indented (2 spaces)")
          break
        end
      end
    end)

    it("supports nested epics (epic within epic)", function()
      -- Create nested epic structure: Epic One → Child Epic → Grandchild task
      local epic1_id = vim.trim(vim.fn.system(string.format("cd %s && bd list --json 2>/dev/null | jq -r '.[] | select(.title == \"Epic One\") | .id'", test_dir)))
      run_bd(string.format("create 'Child Epic' --type epic --priority 2 --parent %s --silent", epic1_id))
      local child_epic_id = vim.trim(vim.fn.system(string.format("cd %s && bd list --json --status=all 2>/dev/null | jq -r '.[] | select(.title == \"Child Epic\") | .id'", test_dir)))
      run_bd(string.format("create 'Grandchild task' --type task --priority 2 --parent %s --silent", child_epic_id))

      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Expand Epic One
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end
      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Child Epic should show with epic icon ▶
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local child_epic_line = nil
      for i, line in ipairs(lines) do
        if line:match("Child Epic") then
          child_epic_line = i
          assert.truthy(line:match("▶"), "Child epic should show ▶ icon")
          assert.truthy(line:match("^  "), "Child epic should be indented")
          break
        end
      end
      assert.truthy(child_epic_line, "Should show child epic")

      -- Expand Child Epic
      vim.api.nvim_win_set_cursor(win, { child_epic_line, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Grandchild should appear at depth 2 (4 spaces)
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_grandchild = false
      for _, line in ipairs(lines) do
        if line:match("Grandchild task") then
          found_grandchild = true
          assert.truthy(line:match("^    "), "Grandchild should be indented 4 spaces")
          break
        end
      end
      assert.is_true(found_grandchild, "Should show grandchild task")
    end)
  end)

  describe("expand shows all children including closed", function()
    pending("expanding epic shows closed children in default open filter", function()
      -- Close one of the epic's children
      local child_id = vim.trim(vim.fn.system(string.format(
        "cd %s && bd list --json --status=all 2>/dev/null | jq -r '.[] | select(.title == \"Task under epic\") | .id'", test_dir)))
      run_bd(string.format("close %s", child_id))

      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      -- Find and expand epic
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end
      assert.truthy(epic_line_num, "Should find epic")

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Both children should appear (open Bug + closed Task)
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_open_child = false
      local found_closed_child = false
      for _, line in ipairs(lines) do
        if line:match("Bug under epic") then found_open_child = true end
        if line:match("Task under epic") then found_closed_child = true end
      end

      assert.is_true(found_open_child, "Should show open child")
      assert.is_true(found_closed_child, "Should show closed child when expanding epic")
    end)

    pending("drill-into epic shows closed children", function()
      -- Close one child
      local child_id = vim.trim(vim.fn.system(string.format(
        "cd %s && bd list --json --status=all 2>/dev/null | jq -r '.[] | select(.title == \"Bug under epic\") | .id'", test_dir)))
      run_bd(string.format("close %s", child_id))

      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find epic and drill in
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "x", false)
      vim.wait(200)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_open = false
      local found_closed = false
      for _, line in ipairs(lines) do
        if line:match("Task under epic") then found_open = true end
        if line:match("Bug under epic") then found_closed = true end
      end

      assert.is_true(found_open, "Should show open child in drill-in")
      assert.is_true(found_closed, "Should show closed child in drill-in")
    end)
  end)

  describe("delete", function()
    pending("d deletes a non-epic bead", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find "Another task"
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local task_line = nil
      for i, line in ipairs(lines) do
        if line:match("Another task") then
          task_line = i
          break
        end
      end
      assert.truthy(task_line, "Should find 'Another task'")

      -- Stub confirm to auto-accept
      local orig_confirm = vim.fn.confirm
      vim.fn.confirm = function() return 1 end

      vim.api.nvim_win_set_cursor(win, { task_line, 0 })
      vim.api.nvim_feedkeys("d", "x", false)
      vim.wait(500)

      vim.fn.confirm = orig_confirm

      -- Verify it's gone from the viewer
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local still_there = false
      for _, line in ipairs(lines) do
        if line:match("Another task") then
          still_there = true
          break
        end
      end
      assert.is_false(still_there, "Deleted bead should be gone from viewer")

      -- Verify it's gone from bd
      local output = vim.fn.system(string.format("cd %s && bd list --json --status=all 2>/dev/null", test_dir))
      assert.is_nil(output:match("Another task"), "Deleted bead should be gone from bd")
    end)

    pending("d on epic prompts and cascade-deletes children", function()
      -- Stub confirm to auto-accept
      local orig_confirm = vim.fn.confirm
      vim.fn.confirm = function() return 1 end

      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find "Epic One"
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line = i
          break
        end
      end
      assert.truthy(epic_line, "Should find 'Epic One'")

      vim.api.nvim_win_set_cursor(win, { epic_line, 0 })
      vim.api.nvim_feedkeys("d", "x", false)
      vim.wait(1000)

      vim.fn.confirm = orig_confirm

      -- Epic should be gone
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_epic = false
      for _, line in ipairs(lines) do
        if line:match("Epic One") then
          found_epic = true
          break
        end
      end
      assert.is_false(found_epic, "Epic should be deleted from viewer")

      -- Children should also be gone from bd
      local output = vim.fn.system(string.format("cd %s && bd list --json --status=all 2>/dev/null", test_dir))
      assert.is_nil(output:match("Task under epic"), "Children should be cascade-deleted")
      assert.is_nil(output:match("Bug under epic"), "Children should be cascade-deleted")
    end)
  end)

  describe("status filters", function()
    it("default shows open beads only", function()
      vim.cmd("Beads")

      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_closed = false
      for _, line in ipairs(lines) do
        if line:match("Closed task") then
          found_closed = true
          break
        end
      end

      assert.is_false(found_closed, "Closed bead should not show in default view")
      assert.is_false(lines[1]:match("%[all%]") ~= nil, "Title should not show [all]")
    end)

    it("C-a shows all beads including closed", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]

      vim.api.nvim_set_current_win(win)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-a>", true, false, true), "x", false)
      vim.wait(200)

      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      assert.truthy(lines[1]:match("%[all%]"), "Title should show [all]")

      local found_closed = false
      for _, line in ipairs(lines) do
        if line:match("Closed task") then
          found_closed = true
          break
        end
      end

      assert.is_true(found_closed, "Should show closed bead")
    end)

    it("C-o returns to open filter", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Switch to all
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-a>", true, false, true), "x", false)
      vim.wait(200)

      -- Back to open
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "x", false)
      vim.wait(200)

      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      assert.is_false(lines[1]:match("%[all%]") ~= nil, "Should not show [all]")

      local found_closed = false
      for _, line in ipairs(lines) do
        if line:match("Closed task") then
          found_closed = true
          break
        end
      end

      assert.is_false(found_closed, "Should not show closed bead")
    end)

    it("preserves expanded state across filter change", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find and expand epic
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Switch to all filter
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-a>", true, false, true), "x", false)
      vim.wait(200)

      -- Check epic still expanded
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local found_expanded = false
      local found_child = false

      for _, line in ipairs(lines) do
        if line:match("Epic One") and line:match("▼") then
          found_expanded = true
        end
        if line:match("Task under epic") then
          found_child = true
        end
      end

      assert.is_true(found_expanded, "Epic should stay expanded")
      assert.is_true(found_child, "Should show epic children after filter change")
    end)
  end)

  describe("help toggle", function()
    it("g? shows help legend", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      vim.api.nvim_feedkeys("g?", "x", false)
      vim.wait(100)

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_keymaps = false
      local found_icons = false

      for _, line in ipairs(lines) do
        if line:match("Keymaps") then found_keymaps = true end
        if line:match("Icons") then found_icons = true end
      end

      assert.is_true(found_keymaps, "Should show Keymaps section")
      assert.is_true(found_icons, "Should show Icons section")
    end)

    it("g? again hides help", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      vim.api.nvim_feedkeys("g?", "x", false)
      vim.wait(100)
      vim.api.nvim_feedkeys("g?", "x", false)
      vim.wait(100)

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_help = false
      for _, line in ipairs(lines) do
        if line:match("Keymaps") then
          found_help = true
          break
        end
      end

      assert.is_false(found_help, "Help should be hidden")
    end)
  end)

  describe("drill in/out", function()
    it("C-] drills into epic showing only children", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find epic
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "x", false)
      vim.wait(200)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- Should show epic name in title
      assert.truthy(lines[1]:match("Epic One"), "Title should show epic name")

      -- Should show the epic itself
      local found_epic = false
      for _, line in ipairs(lines) do
        if line:match("Epic One") and not line:match("Beads") then
          found_epic = true
          break
        end
      end
      assert.is_true(found_epic, "Should show epic at top")

      -- Should show children
      local found_child = false
      for _, line in ipairs(lines) do
        if line:match("Task under epic") then
          found_child = true
          break
        end
      end
      assert.is_true(found_child, "Should show children")

      -- Should NOT show other epics/tasks
      local found_other_task = false
      for _, line in ipairs(lines) do
        if line:match("Standalone task") then
          found_other_task = true
          break
        end
      end
      assert.is_false(found_other_task, "Should not show unrelated tasks")
    end)

    it("- drills up to full list", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Drill in
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "x", false)
      vim.wait(200)

      -- Drill out
      vim.api.nvim_feedkeys("-", "x", false)
      vim.wait(200)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- Should show all beads again
      local found_standalone = false
      for _, line in ipairs(lines) do
        if line:match("Standalone task") then
          found_standalone = true
          break
        end
      end

      assert.is_true(found_standalone, "Should show all beads after drill up")
      assert.is_nil(lines[1]:match(">"), "Title should not show drill-in indicator")
    end)

    it("filter change while drilled in stays scoped", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Drill in
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local epic_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Epic One") then
          epic_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { epic_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "x", false)
      vim.wait(200)

      -- Change filter
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-a>", true, false, true), "x", false)
      vim.wait(200)

      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- Should still be drilled in
      assert.truthy(lines[1]:match("Epic One"), "Should still show epic in title")
      assert.truthy(lines[1]:match("%[all%]"), "Should show [all] filter")

      -- Should NOT show unrelated beads
      local found_standalone = false
      for _, line in ipairs(lines) do
        if line:match("Standalone task") then
          found_standalone = true
          break
        end
      end

      assert.is_false(found_standalone, "Should not show beads from outside scoped epic")
    end)
  end)

  describe("gd file navigation", function()
    pending("parseFileRef matches path:line-line pattern", function()
      vim.cmd("Beads")
      local main_win = vim.api.nvim_tabpage_list_wins(0)[2]
      vim.api.nvim_set_current_win(main_win)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(main_win, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "see src/app.py:10-20 for details" })
      vim.api.nvim_win_set_cursor(main_win, { 1, 6 })

      local t = require("beads.viewer")._test
      local path, ls, le = t.parseFileRef()
      eq("src/app.py", path)
      eq(10, ls)
      eq(20, le)
    end)

    it("parseFileRef matches path:line pattern (no range)", function()
      vim.cmd("Beads")
      local main_win = vim.api.nvim_tabpage_list_wins(0)[2]
      vim.api.nvim_set_current_win(main_win)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(main_win, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "check src/app.py:42 here" })
      vim.api.nvim_win_set_cursor(main_win, { 1, 8 })

      local t = require("beads.viewer")._test
      local path, ls, le = t.parseFileRef()
      eq("src/app.py", path)
      eq(42, ls)
      assert.is_nil(le)
    end)

    it("openFileRef opens file at correct line", function()
      -- Create a test file in the test repo
      local file_path = test_dir .. "/src/test_file.py"
      vim.fn.mkdir(test_dir .. "/src", "p")
      local lines = {}
      for i = 1, 50 do lines[i] = "# line " .. i end
      vim.fn.writefile(lines, file_path)

      vim.cmd("Beads")
      local t = require("beads.viewer")._test
      t.state.cwd = test_dir

      t.openFileRef("src/test_file.py", 25, nil)

      local cursor = vim.api.nvim_win_get_cursor(0)
      eq(25, cursor[1], "Should jump to line 25")
      local buf_name = vim.api.nvim_buf_get_name(0)
      assert.truthy(buf_name:match("test_file%.py$"), "Should open test_file.py")
    end)

    it("openFileRef with range positions cursor at start line", function()
      -- Create a test file
      local file_path = test_dir .. "/src/range_test.py"
      vim.fn.mkdir(test_dir .. "/src", "p")
      local lines = {}
      for i = 1, 50 do lines[i] = "# line " .. i end
      vim.fn.writefile(lines, file_path)

      vim.cmd("Beads")
      local t = require("beads.viewer")._test
      t.state.cwd = test_dir

      t.openFileRef("src/range_test.py", 10, 15)

      local cursor = vim.api.nvim_win_get_cursor(0)
      eq(10, cursor[1], "Should position cursor at start of range")
      local buf_name = vim.api.nvim_buf_get_name(0)
      assert.truthy(buf_name:match("range_test%.py$"), "Should open range_test.py")
    end)

    it("openFileRef notifies when file not found", function()
      vim.cmd("Beads")
      local t = require("beads.viewer")._test
      t.state.cwd = test_dir

      local notifications = {}
      local orig_notify = vim.notify
      vim.notify = function(msg, level) table.insert(notifications, { msg = msg, level = level }) end

      t.openFileRef("nonexistent/file.py", 1, nil)

      vim.notify = orig_notify

      assert.is_true(#notifications > 0, "Should notify about missing file")
      assert.truthy(notifications[1].msg:match("not found"), "Should mention file not found")
    end)
  end)

  describe("details view", function()
    it("o opens details in main window (2-pane layout)", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Find task line
      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local task_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Standalone task") then
          task_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { task_line_num, 0 })
      vim.api.nvim_feedkeys("o", "x", false)
      vim.wait(100)

      local wins = vim.api.nvim_tabpage_list_wins(0)
      eq(2, #wins, "Should have 2 windows (not 3)")

      -- Detail window should show bead:// buffer
      local main_win = wins[1] == win and wins[2] or wins[1]
      local detail_buf = vim.api.nvim_win_get_buf(main_win)
      local buf_name = vim.api.nvim_buf_get_name(detail_buf)
      assert.truthy(buf_name:match("/tmp/beads/"), "Main window should show bead details")
    end)

    it("Enter on task opens details (same as o)", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local task_line_num = nil
      for i, line in ipairs(lines) do
        if line:match("Standalone task") then
          task_line_num = i
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { task_line_num, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      local wins = vim.api.nvim_tabpage_list_wins(0)
      eq(2, #wins, "Should have 2 windows")

      local main_win = wins[1] == win and wins[2] or wins[1]
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(main_win))
      assert.truthy(buf_name:match("/tmp/beads/"), "Should open details")
    end)
  end)

  describe("highlights", function()
    it("applies priority colors", function()
      vim.cmd("Beads")
      local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(0)[1])

      -- Find P0 and P1 lines
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local p0_line = nil
      local p1_line = nil

      for i, line in ipairs(lines) do
        if line:match("P0") and not p0_line then p0_line = i - 1 end  -- 0-indexed
        if line:match("P1") and not p1_line then p1_line = i - 1 end
      end

      -- Check namespace has highlights
      local ns = vim.api.nvim_create_namespace("beads_viewer")
      local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })

      assert.is_true(#marks > 0, "Should have highlight marks")
    end)
  end)

  describe("refresh", function()
    it("r refreshes bead list", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Create new bead (wait for bd command to complete)
      run_bd("create 'New bead' --type task --priority 1")
      vim.wait(300)

      -- Refresh
      vim.api.nvim_feedkeys("r", "x", false)
      vim.wait(300)

      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local found_new = false
      for _, line in ipairs(lines) do
        if line:match("New bead") then
          found_new = true
          break
        end
      end

      assert.is_true(found_new, "Should show newly created bead after refresh")
    end)
  end)

  describe("state persistence", function()
    local function findLineNumber(buf, pattern)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:match(pattern) then return i end
      end
    end

    local function bufLines(buf)
      return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end

    local function findLineContent(buf, pattern)
      for _, line in ipairs(bufLines(buf)) do
        if line:match(pattern) then return line end
      end
    end

    it("restores cursor position after close/reopen", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_set_current_win(win)

      local target_line = findLineNumber(buf, "Standalone task")
      assert.truthy(target_line, "Should find Standalone task line")
      vim.api.nvim_win_set_cursor(win, { target_line, 0 })

      -- Close
      vim.cmd("Beads")
      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should be closed")

      -- Reopen
      vim.cmd("Beads")
      win = vim.api.nvim_tabpage_list_wins(0)[1]
      local cursor = vim.api.nvim_win_get_cursor(win)
      eq(target_line, cursor[1], "Cursor should be restored to Standalone task line")
    end)

    it("restores cursor position after :only closes sidebar", function()
      vim.cmd("Beads")
      local wins = vim.api.nvim_tabpage_list_wins(0)
      local sidebar_win = wins[1]
      local main_win = wins[2]
      local buf = vim.api.nvim_win_get_buf(sidebar_win)
      vim.api.nvim_set_current_win(sidebar_win)

      local target_line = findLineNumber(buf, "Standalone task")
      assert.truthy(target_line, "Should find Standalone task line")
      vim.api.nvim_win_set_cursor(sidebar_win, { target_line, 0 })

      -- Switch to main window (triggers WinLeave on sidebar, saving cursor)
      vim.api.nvim_set_current_win(main_win)
      vim.wait(50)

      -- Close sidebar via :only from main window
      vim.cmd("only")
      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should have 1 window after :only")

      -- Reopen
      vim.cmd("Beads")
      local new_win = vim.api.nvim_tabpage_list_wins(0)[1]
      local cursor = vim.api.nvim_win_get_cursor(new_win)
      eq(target_line, cursor[1], "Cursor should be restored after :only")
    end)

    it("preserves scoped epic across close/reopen", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_set_current_win(win)

      -- Drill into Epic One
      local epic_line = findLineNumber(buf, "Epic One")
      assert.truthy(epic_line, "Should find Epic One")
      vim.api.nvim_win_set_cursor(win, { epic_line, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "x", false)
      vim.wait(200)

      -- Verify drilled in
      buf = vim.api.nvim_win_get_buf(win)
      assert.truthy(findLineContent(buf, "Epic One"), "Should show Epic One in scoped view")

      -- Close
      vim.cmd("Beads")
      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should be closed")

      -- Reopen
      vim.cmd("Beads")
      win = vim.api.nvim_tabpage_list_wins(0)[1]
      buf = vim.api.nvim_win_get_buf(win)
      local lines = bufLines(buf)

      -- Title should show epic name with >
      assert.truthy(lines[1]:match(">"), "Title should show drill-in indicator")
      assert.truthy(lines[1]:match("Epic One"), "Title should show epic name")

      -- Should NOT show standalone tasks
      assert.is_nil(findLineContent(buf, "Standalone task"), "Should not show unrelated tasks")
    end)

    it("preserves filter across close/reopen", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      vim.api.nvim_set_current_win(win)

      -- Switch to "all" filter
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-a>", true, false, true), "x", false)
      vim.wait(200)

      -- Verify filter applied
      local buf = vim.api.nvim_win_get_buf(win)
      local lines = bufLines(buf)
      assert.truthy(lines[1]:match("%[all%]"), "Should show [all] before close")

      -- Close
      vim.cmd("Beads")
      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should be closed")

      -- Reopen
      vim.cmd("Beads")
      win = vim.api.nvim_tabpage_list_wins(0)[1]
      buf = vim.api.nvim_win_get_buf(win)
      lines = bufLines(buf)

      assert.truthy(lines[1]:match("%[all%]"), "Should still show [all] after reopen")

      -- Should show closed bead
      assert.truthy(findLineContent(buf, "Closed task"), "Should show closed bead with [all] filter")
    end)

    it("re-fetches expanded children on reopen", function()
      vim.cmd("Beads")
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_set_current_win(win)

      -- Expand Epic One
      local epic_line = findLineNumber(buf, "Epic One")
      assert.truthy(epic_line, "Should find Epic One")
      vim.api.nvim_win_set_cursor(win, { epic_line, 0 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
      vim.wait(100)

      -- Verify children visible
      buf = vim.api.nvim_win_get_buf(win)
      assert.truthy(findLineContent(buf, "Task under epic"), "Children should be visible after expand")

      -- Close
      vim.cmd("Beads")
      eq(1, #vim.api.nvim_tabpage_list_wins(0), "Should be closed")

      -- Reopen
      vim.cmd("Beads")
      win = vim.api.nvim_tabpage_list_wins(0)[1]
      buf = vim.api.nvim_win_get_buf(win)

      -- Epic should still show expanded icon
      local epic_content = findLineContent(buf, "Epic One")
      assert.truthy(epic_content, "Should find Epic One after reopen")
      assert.truthy(epic_content:match("▼"), "Epic should show expanded icon ▼ after reopen")

      -- Children should be visible (re-fetched)
      assert.truthy(findLineContent(buf, "Task under epic"), "Children should be re-fetched and visible after reopen")
    end)
  end)
end)
