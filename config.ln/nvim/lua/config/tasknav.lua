-- suss-tasks code-link navigation
--
-- Task files reference code with root-relative GitHub-style markdown links,
-- either inline or as reference links whose targets are collected at the
-- bottom of the file (keeps wide table cells narrow):
--   [label](/git-root-relative-path#L31)        inline, single line
--   [label](/git-root-relative-path#L31-L71)    inline, line range
--   [label][ref] … [ref]: /path#L31            reference link + definition
--
-- `gd` on such a link opens the target in the current window, highlights the
-- range via interestingwords, and positions the viewport 1/4 from the top.
-- When the cursor is not on a code link, it falls back to LSP go-to-definition
-- so plain markdown links (marksman) keep working.

local function gitRoot()
  local dir = vim.fn.expand('%:p:h')
  local root = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then return nil end
  return vim.trim(root)
end

-- "/path/File.tsx?plain=1#L31-L71" -> "path/File.tsx", 31, 71
local function parseUrl(url)
  local path = url:gsub('#.*$', ''):gsub('%?.*$', ''):gsub('^/', '')
  local fragment = url:match('#(.*)$') or ''
  local line_start = tonumber(fragment:match('^L(%d+)'))
  local line_end = tonumber(fragment:match('%-L(%d+)'))
  if path == '' or not line_start then return nil end
  return path, line_start, line_end
end

-- "[ref]: /path#L31" definitions live anywhere in the buffer (we collect them
-- at the bottom). Resolve a reference label to its URL.
local function resolveReference(ref)
  local pattern = '^%s*%[' .. vim.pesc(ref) .. '%]:%s*(%S+)'
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local url = line:match(pattern)
    if url then return url end
  end
end

local function parseLinkUnderCursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local pos = 1
  while true do
    local open_bracket, close_bracket, label = line:find('%[([^%]]*)%]', pos)
    if not open_bracket then return end

    local after = line:sub(close_bracket + 1)
    local inline_url = after:match('^%(([^%)]+)%)')
    local ref = after:match('^%[([^%]]*)%]') -- full [label][ref] or collapsed [label][]

    local span_end = close_bracket
    if inline_url then
      span_end = close_bracket + #inline_url + 2 -- (url)
    elseif ref ~= nil then
      span_end = close_bracket + #ref + 2 -- [ref]
    end

    if col >= open_bracket and col <= span_end then
      if inline_url then return parseUrl(inline_url) end
      -- reference link: use the explicit ref, else the label (collapsed/shortcut)
      local key = (ref ~= nil and ref ~= '') and ref or label
      local url = resolveReference(key)
      if not url then return end
      return parseUrl(url)
    end

    pos = close_bracket + 1
  end
end

local function highlightRange(line_start, line_end)
  local ok, iw = pcall(require, 'interestingwords')
  if not ok then return end

  iw.UncolorAllWords(false)

  line_end = math.min(line_end or line_start, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { line_start, 0 })
  local span = line_end - line_start
  vim.cmd('normal! V' .. (span > 0 and span .. 'j' or ''))
  iw.InterestingWord('v', false)
end

local function positionViewport(target_line)
  vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  vim.cmd('normal! zt')
  local quarter = math.floor(vim.api.nvim_win_get_height(0) / 4)
  if quarter > 0 then
    local scroll_up = vim.api.nvim_replace_termcodes('<C-y>', true, false, true)
    vim.api.nvim_feedkeys(quarter .. scroll_up, 'nx', false)
  end
end

local function openCodeLink(path, line_start, line_end)
  local root = gitRoot()
  if not root then
    vim.notify('tasknav: not in a git repo', vim.log.levels.WARN)
    return
  end

  local abs_path = root .. '/' .. path
  if vim.fn.filereadable(abs_path) ~= 1 then
    vim.notify('tasknav: file not found: ' .. abs_path, vim.log.levels.WARN)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(abs_path))
  highlightRange(line_start, line_end)
  positionViewport(line_start)
end

local function followLink()
  local path, line_start, line_end = parseLinkUnderCursor()
  if path then
    openCodeLink(path, line_start, line_end)
  else
    vim.lsp.buf.definition()
  end
end

local function isTaskFile(buf)
  return vim.api.nvim_buf_get_name(buf):match('/suss%-tasks/.*%.md$') ~= nil
end

-- Bind on the next tick so we win over the synchronous LspAttach handler
-- (lsp.lua maps gd -> vim.lsp.buf.definition for marksman buffers).
local function bindLater(buf)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) and isTaskFile(buf) then
      vim.keymap.set('n', 'gd', followLink, {
        buffer = buf,
        silent = true,
        desc = 'suss-tasks: follow code link / LSP definition',
      })
    end
  end)
end

local function setup()
  local group = vim.api.nvim_create_augroup('SussTasksNav', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWinEnter' }, {
    group = group,
    pattern = '*/suss-tasks/*',
    callback = function(args) bindLater(args.buf) end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args) bindLater(args.buf) end,
  })
end

return {
  setup = setup,
  _test = {
    parseUrl = parseUrl,
    resolveReference = resolveReference,
    parseLinkUnderCursor = parseLinkUnderCursor,
    highlightRange = highlightRange,
    positionViewport = positionViewport,
    openCodeLink = openCodeLink,
    followLink = followLink,
    gitRoot = gitRoot,
  },
}
