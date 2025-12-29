-- MRU (Most Recently Used) files tracker
-- Tracks recently opened files with cursor position

local M = {}

-- MRU file location
M.mru_file = vim.fn.expand('~/.local/share/nvim_mru.txt')

-- Files to ignore
local function should_ignore(filepath)
  if not filepath or filepath == '' then
    return true
  end

  local ft = vim.bo.filetype

  -- Ignore certain filetypes
  if ft == 'git' or
     ft == 'gitcommit' or
     ft == 'gitrebase' or
     ft == 'fugitive' or
     ft == 'help' or
     ft == 'qf' or
     ft == 'fzf' then
    return true
  end

  -- Ignore temp files and special paths
  if filepath:match('/private/var/folders/') or
     filepath:match('nvim%.runtime') or
     filepath:match('fugitiveblame') or
     filepath:match('/var/folders/.*nvim') or
     filepath:match('%.git/index') or
     not vim.fn.filereadable(filepath) == 1 then
    return true
  end

  return false
end

-- Save current file to MRU
function M.save_mru()
  local filepath = vim.fn.expand('%:p')

  if should_ignore(filepath) then
    return
  end

  -- Get cursor position
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = pos[1]
  local col = pos[2] + 1 -- Lua is 0-indexed, vim is 1-indexed

  -- Format: filepath:line:column
  local entry = string.format('%s:%d:%d', filepath, line, col)

  -- Read existing entries with error handling
  local entries = {}
  local seen = {}

  if vim.fn.filereadable(M.mru_file) == 1 then
    local ok, err = pcall(function()
      for line_text in io.lines(M.mru_file) do
        local file = line_text:match('^([^:]+):')
        if file and not seen[file] and file ~= filepath then
          table.insert(entries, line_text)
          seen[file] = true
        end
      end
    end)

    -- If file is corrupted, start fresh
    if not ok then
      entries = {}
      seen = {}
    end
  end

  -- Add current entry at the top
  table.insert(entries, 1, entry)

  -- Keep only last 100 entries
  local max_entries = 100
  if #entries > max_entries then
    for i = max_entries + 1, #entries do
      entries[i] = nil
    end
  end

  -- Write back to file with error handling
  local ok, err = pcall(function()
    local file = io.open(M.mru_file, 'w')
    if file then
      for _, e in ipairs(entries) do
        file:write(e .. '\n')
      end
      file:close()
    end
  end)

  -- Silently fail if write fails (e.g., disk full, permissions)
  -- User will just miss this MRU entry, not a critical failure
end

-- Show MRU with fzf
function M.show_mru()
  if vim.fn.filereadable(M.mru_file) ~= 1 then
    print('No MRU history found')
    return
  end

  -- Use fzf-lua if available, otherwise fall back to vim.ui.select
  local fzf_lua_ok, fzf_lua = pcall(require, 'fzf-lua')

  if fzf_lua_ok then
    fzf_lua.fzf_exec('cat ' .. M.mru_file, {
      prompt = 'MRU> ',
      winopts = {
        fullscreen = true,
        preview = {
          layout = 'vertical',
          vertical = 'up:50%',
        },
      },
      previewer = 'builtin',
      actions = {
        ['default'] = function(selected)
          if not selected or #selected == 0 then return end

          local entry = selected[1]
          local filepath, line, col = entry:match('^([^:]+):(%d+):(%d+)')

          if filepath and line and col then
            vim.cmd('edit ' .. filepath)
            vim.api.nvim_win_set_cursor(0, {tonumber(line), tonumber(col) - 1})
            vim.cmd('normal! zz')
          end
        end
      }
    })
  else
    -- Fallback to basic implementation
    print('fzf-lua not available, install it for better MRU experience')
  end
end

-- Setup autocmds for MRU tracking
function M.setup()
  -- Ensure directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(M.mru_file, ':h'), 'p')

  -- Create autocommands to track file usage
  local group = vim.api.nvim_create_augroup('MRU', { clear = true })

  vim.api.nvim_create_autocmd({'BufReadPost', 'BufWinEnter', 'BufHidden'}, {
    group = group,
    callback = function()
      vim.defer_fn(M.save_mru, 100)
    end
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = M.save_mru
  })

  -- Set up keymap for 1m
  vim.keymap.set('n', '1m', M.show_mru, { desc = 'MRU files', noremap = true, silent = true })
end

return M
