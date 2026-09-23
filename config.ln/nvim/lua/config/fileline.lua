local function parse_file_line_col(name)
  local path, line, col = name:match('^(.-):(%d+):?(%d*)$')
  if not path or vim.fn.filereadable(path) ~= 1 then return nil end
  return path, tonumber(line), tonumber(col) or 1
end

local function clamp_cursor(line, col)
  local last_line = vim.api.nvim_buf_line_count(0)
  return { math.min(line, last_line), math.max(col - 1, 0) }
end

local function open_real_file_instead(args)
  local path, line, col = parse_file_line_col(vim.api.nvim_buf_get_name(args.buf))
  if not path then return end
  vim.cmd.edit({ vim.fn.fnameescape(path), mods = { keepalt = true } })
  vim.api.nvim_buf_delete(args.buf, { force = true })
  vim.api.nvim_win_set_cursor(0, clamp_cursor(line, col))
end

local function setup()
  local group = vim.api.nvim_create_augroup('FileLineCol', { clear = true })
  vim.api.nvim_create_autocmd('BufNewFile', {
    group = group,
    nested = true,
    callback = open_real_file_instead,
  })
end

return { setup = setup }
