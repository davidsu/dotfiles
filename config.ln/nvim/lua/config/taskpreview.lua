local function gitRootOf(dir)
  local root = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then return nil end
  return vim.trim(root)
end

local repoRootCache = {}
local function repoRoot()
  local dir = vim.fn.expand('%:p:h')
  if not repoRootCache[dir] then
    repoRootCache[dir] = gitRootOf(dir)
  end
  return repoRootCache[dir]
end

local function toLocalFileUrl(root, url)
  local path = url:gsub('[?#].*$', ''):gsub('^/', '')
  return 'file://' .. root .. '/' .. path
end

local function rewriteRootRelativeLinks(line, root)
  local withInlineLinks = line:gsub('%]%((/[^%s%)]+)%)', function(url)
    return '](' .. toLocalFileUrl(root, url) .. ')'
  end)
  return withInlineLinks:gsub('^(%s*%[[^%]]+%]:%s*)(/%S+)', function(prefix, url)
    return prefix .. toLocalFileUrl(root, url)
  end)
end

local function rewriteCodeLinks(lines, root)
  return vim.tbl_map(function(line) return rewriteRootRelativeLinks(line, root) end, lines)
end

local activePreviewBuf

local function disposeActivePreview()
  if activePreviewBuf and vim.api.nvim_buf_is_valid(activePreviewBuf) then
    vim.api.nvim_buf_delete(activePreviewBuf, { force = true })
  end
  activePreviewBuf = nil
end

local function previewBufferName(sourceBuf)
  return '[TaskPreview] ' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(sourceBuf), ':t')
end

local function buildPreviewBuffer(sourceBuf, root)
  local sourceLines = vim.api.nvim_buf_get_lines(sourceBuf, 0, -1, false)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rewriteCodeLinks(sourceLines, root))
  vim.api.nvim_buf_set_name(buf, previewBufferName(sourceBuf))
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].modifiable = false
  return buf
end

local function openInSplit(buf)
  vim.cmd('botright vsplit')
  vim.api.nvim_set_current_buf(buf)
end

local function open()
  local sourceBuf = vim.api.nvim_get_current_buf()
  local root = repoRoot()
  if not root then
    vim.notify('TaskPreview: not in a git repo', vim.log.levels.WARN)
    return
  end
  disposeActivePreview()
  activePreviewBuf = buildPreviewBuffer(sourceBuf, root)
  openInSplit(activePreviewBuf)
  vim.fn['mkdp#util#open_preview_page']()
end

local function setup()
  vim.api.nvim_create_user_command('TaskPreview', open, {
    desc = 'Preview the current task doc with code links resolved to local files',
  })
end

return {
  setup = setup,
  open = open,
  rewriteCodeLinks = rewriteCodeLinks,
  _test = {
    toLocalFileUrl = toLocalFileUrl,
    rewriteRootRelativeLinks = rewriteRootRelativeLinks,
    rewriteCodeLinks = rewriteCodeLinks,
    repoRoot = repoRoot,
  },
}
