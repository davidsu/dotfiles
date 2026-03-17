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

local git_cache = {}

-- For worktree files, returns the equivalent path in the main repo (or nil)
local function main_repo_path(filepath)
  local dir = vim.fn.fnamemodify(filepath, ':h')

  if git_cache[dir] ~= nil then
    if not git_cache[dir] then return nil end
    local info = git_cache[dir]
    local relpath = filepath:sub(#info.toplevel + 2)
    local main = info.repo_root .. '/' .. relpath
    return main ~= filepath and main or nil
  end

  local result = vim.fn.systemlist({ 'git', '-C', dir, 'rev-parse', '--git-common-dir', '--show-toplevel' })
  if vim.v.shell_error ~= 0 or #result < 2 then
    git_cache[dir] = false
    return nil
  end

  local git_common_dir, toplevel = result[1], result[2]
  if not git_common_dir:match('^/') then
    git_common_dir = vim.fn.fnamemodify(dir .. '/' .. git_common_dir, ':p'):gsub('/$', '')
  end

  local repo_root = vim.fn.fnamemodify(git_common_dir, ':h')
  git_cache[dir] = { repo_root = repo_root, toplevel = toplevel }

  local relpath = filepath:sub(#toplevel + 2)
  local main = repo_root .. '/' .. relpath
  return main ~= filepath and main or nil
end

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

local function read_mru_entries()
  if vim.fn.filereadable(mru_file) ~= 1 then return {} end
  local entries = {}
  pcall(function()
    for line in io.lines(mru_file) do
      if line:match('^.+:%d+:%d+$') then
        entries[#entries + 1] = line
      end
    end
  end)
  return entries
end

local function prepend_entry(path, line, col, entries)
  local filtered = {}
  for _, e in ipairs(entries) do
    if not vim.startswith(e, path .. ':') then
      filtered[#filtered + 1] = e
    end
  end
  table.insert(filtered, 1, string.format('%s:%d:%d', path, line, col))
  return filtered
end

local function write_mru_entries(entries)
  pcall(function()
    local file = io.open(mru_file, 'w')
    if file then
      for i = 1, math.min(#entries, 600) do
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
  
  -- Resolve path to absolute (handle relative paths starting with //)
  path = vim.fn.fnamemodify(path, ':p')
  
  -- If path still starts with //, it's malformed - try to resolve from cwd
  if path:match('^//') then
    path = vim.fn.getcwd() .. '/' .. path:gsub('^/+', '')
    path = vim.fn.fnamemodify(path, ':p')
  end
  
  return path
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

  local entries = read_mru_entries()

  local line, col
  if not force_update then
    for _, e in ipairs(entries) do
      local p, l, c = e:match('^(.+):(%d+):(%d+)$')
      if p == filepath then line, col = tonumber(l), tonumber(c); break end
    end
  end
  if not line then
    line, col = get_cursor_pos(bufnr)
    if not line then return end
  end

  entries = prepend_entry(filepath, line, col, entries)

  local main = main_repo_path(filepath)
  if main then entries = prepend_entry(main, line, col, entries) end

  write_mru_entries(entries)
end

local function parse_mru_entry(entry)
  local filepath, line, col = entry:match('^([^:]+):(%d+):(%d+)')
  if filepath and line and col then
    return filepath, tonumber(line), tonumber(col)
  end
  return nil, nil, nil
end

local function mru_entries_to_qf(selected)
  local items = {}
  for _, entry in ipairs(selected) do
    local filepath, line, col = parse_mru_entry(entry)
    if filepath then
      items[#items + 1] = { filename = filepath, lnum = line, col = col }
    end
  end
  vim.fn.setqflist({}, ' ', { nr = '$', items = items, title = '[MRU]' })
  vim.cmd('botright copen')
end

local function open_mru_file(selected)
  if not selected or #selected == 0 then return end
  local filepath, line, col = parse_mru_entry(selected[1])
  if filepath then
    vim.cmd('edit ' .. filepath)
    vim.api.nvim_win_set_cursor(0, { line, col - 1 })
    vim.cmd('normal! zz')
  end
  if #selected > 1 then
    mru_entries_to_qf(selected)
    vim.cmd('wincmd p')
  end
end

local function show_mru_with_fzf_lua()
  local fzf_lua_ok, fzf_lua = pcall(require, 'fzf-lua')
  if not fzf_lua_ok then return false end

  fzf_lua.fzf_exec('cat ' .. mru_file, {
    prompt = 'MRU> ',
    fzf_opts = { ['--no-sort'] = '', ['--multi'] = '' },
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
  vim.keymap.set('n', '<C-;>', show_mru, { desc = 'MRU files', noremap = true, silent = true })
end

return {
  setup = setup,
  show_mru = show_mru,
  save_mru = save_mru,
}
