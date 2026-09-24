local function parse_file_line_col(name)
  local path, line, col = name:match('^(.-):(%d+):?(%d*)$')
  if not path or vim.fn.filereadable(path) ~= 1 then return nil end
  return path, tonumber(line), tonumber(col) or 1
end

local function jump_to(line, col)
  local last_line = vim.api.nvim_buf_line_count(0)
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { math.min(line, last_line), math.max(col - 1, 0) })
end

local function is_current_file(path)
  return vim.fn.fnamemodify(path, ':p') == vim.api.nvim_buf_get_name(0)
end

local function open_at(path, line, col)
  if not is_current_file(path) then vim.cmd.edit(vim.fn.fnameescape(path)) end
  jump_to(line, col)
end

local function edit_command_target(cmdline)
  local command, target = cmdline:match('^%s*(%a+)%s+(.-)%s*$')
  if command and vim.startswith('edit', command) then return target end
end

local function intercept_edit_command()
  if vim.fn.getcmdtype() ~= ':' then return end
  local path, line, col = parse_file_line_col(edit_command_target(vim.fn.getcmdline()) or '')
  if not path then return end
  vim.cmd('let v:event.abort = v:true')
  vim.schedule(function() open_at(path, line, col) end)
end

local function open_real_file_instead(args)
  local path, line, col = parse_file_line_col(vim.api.nvim_buf_get_name(args.buf))
  if not path then return end
  vim.cmd.edit({ vim.fn.fnameescape(path), mods = { keepalt = true } })
  vim.api.nvim_buf_delete(args.buf, { force = true })
  jump_to(line, col)
end

local function setup()
  local group = vim.api.nvim_create_augroup('FileLineCol', { clear = true })
  vim.api.nvim_create_autocmd('CmdlineLeave', { group = group, callback = intercept_edit_command })
  vim.api.nvim_create_autocmd('BufNewFile', {
    group = group,
    nested = true,
    callback = open_real_file_instead,
  })
end

return { setup = setup }
