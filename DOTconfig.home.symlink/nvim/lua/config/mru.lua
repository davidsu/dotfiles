-- MRU (Most Recently Used) files tracker
-- Tracks recently opened files with cursor position

local mru_file = vim.fn.expand('~/.local/share/nvim_mru.txt')

local IGNORED_FTS = {
  'git', 'gitcommit', 'gitrebase', 'fugitive', 'help', 'qf', 'fzf', 'health', 'NvimTree'
}

local IGNORED_PATTERNS = {
  '^fugitive://', '^health://', 'NvimTree_', '/private/var/folders/',
  'nvim%.runtime', 'fugitiveblame', '/var/folders/.*nvim', '%.git/index',
  '/tmp/beads/'
}

local function should_ignore(filepath)
  if not filepath or filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    return true
  end

  local ft = vim.bo.filetype
  for _, ignored in ipairs(IGNORED_FTS) do
    if ft == ignored then return true end
  end

  for _, pattern in ipairs(IGNORED_PATTERNS) do
    if filepath:match(pattern) then return true end
  end

  return false
end

local function read_mru_entries(target_path)
  local entries = {}
  local seen = {}
  local existing_entry = nil

  if vim.fn.filereadable(mru_file) == 1 then
    pcall(function()
      for line in io.lines(mru_file) do
        local path = line:match('^([^:]+):')
        if path then
          if path == target_path then
            existing_entry = line
          elseif not seen[path] then
            table.insert(entries, line)
            seen[path] = true
          end
        end
      end
    end)
  end
  return entries, existing_entry
end

local function write_mru_entries(entries)
  pcall(function()
    local file = io.open(mru_file, 'w')
    if file then
      for i = 1, math.min(#entries, 100) do
        file:write(entries[i] .. '\n')
      end
      file:close()
    end
  end)
end

local function get_buffer_info(bufnr)
  if bufnr and not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  local path = bufnr and vim.api.nvim_buf_get_name(bufnr) or vim.fn.expand('%:p')
  if path == '' then return nil end
  return vim.fn.fnamemodify(path, ':p')
end

local function get_cursor_pos(bufnr)
  local win = (bufnr and vim.fn.bufwinid(bufnr)) or 0
  if win == -1 or not vim.api.nvim_win_is_valid(win) then return nil end
  local pos = vim.api.nvim_win_get_cursor(win)
  return pos[1], pos[2] + 1
end

local function save_mru(bufnr, force_update)
  local filepath = get_buffer_info(bufnr)
  if not filepath or should_ignore(filepath) then return end

  local entries, existing_entry = read_mru_entries(filepath)
  local entry_to_save

  if existing_entry and not force_update then
    entry_to_save = existing_entry
  else
    local line, col = get_cursor_pos(bufnr)
    if not line then return end
    entry_to_save = string.format('%s:%d:%d', filepath, line, col)
  end

  table.insert(entries, 1, entry_to_save)
  write_mru_entries(entries)
end

local function parse_mru_entry(entry)
  local filepath, line, col = entry:match('^([^:]+):(%d+):(%d+)')
  if filepath and line and col then
    return filepath, tonumber(line), tonumber(col)
  end
  return nil, nil, nil
end

local function open_mru_file(selected)
  if not selected or #selected == 0 then return end
  local filepath, line, col = parse_mru_entry(selected[1])
  if filepath then
    vim.cmd('edit ' .. filepath)
    vim.api.nvim_win_set_cursor(0, {line, col - 1})
    vim.cmd('normal! zz')
  end
end

local function show_mru_with_fzf_lua()
  local fzf_lua_ok, fzf_lua = pcall(require, 'fzf-lua')
  if not fzf_lua_ok then return false end

  fzf_lua.fzf_exec('cat ' .. mru_file, {
    prompt = 'MRU> ',
    winopts = { fullscreen = true, preview = { layout = 'vertical', vertical = 'up:50%' } },
    previewer = 'builtin',
    actions = {
      ['default'] = open_mru_file
    }
  })
  return true
end

local function show_mru()
  if vim.fn.filereadable(mru_file) ~= 1 then
    print('No MRU history found')
    return
  end
  if not show_mru_with_fzf_lua() then
    print('fzf-lua not available')
  end
end

local function on_buffer_open(args)
  save_mru(args.buf, false)
end

local function on_buffer_update(args)
  save_mru(args.buf, true)
end

local function setup()
  vim.fn.mkdir(vim.fn.fnamemodify(mru_file, ':h'), 'p')
  local group = vim.api.nvim_create_augroup('MRU', { clear = true })

  vim.api.nvim_create_autocmd({'BufReadPost', 'BufWinEnter'}, {
    group = group,
    callback = on_buffer_open
  })

  vim.api.nvim_create_autocmd({'BufWritePost', 'BufHidden', 'BufLeave', 'VimLeavePre'}, {
    group = group,
    callback = on_buffer_update
  })

  vim.keymap.set('n', '1m', show_mru, { desc = 'MRU files', noremap = true, silent = true })
end

return {
  setup = setup,
  show_mru = show_mru,
  save_mru = save_mru,
}
