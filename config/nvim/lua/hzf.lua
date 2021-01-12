local M = {}
function concat(t1, ...) 
  for _,t in ipairs{...} do
    for __,val in pairs(t) do
      table.insert(t1, val)
    end
  end
  return t1
end

function scandir(dir)
  local result = {}
  if string.match(dir, 'node_modules$') then
    return result
  end
  local i = vim.loop.fs_scandir(dir)
  if not i then return end
  local file = vim.loop.fs_scandir_next(i)
  while file do
    file = dir .. '/' .. file
    if vim.fn.isdirectory(file) == 1 then
      concat(result, scandir(file))
    elseif string.match(file, '%.lua$') or string.match(file, '%.[tj]s$') then
      table.insert(result, file)
    end
    file = vim.loop.fs_scandir_next(i)
  end
  return result
end

function getScripts()
  return concat(
    vim.fn.map(vim.fn['scriptease#scriptnames_qflist'](), 'v:val.filename'),
    scandir(os.getenv('HOME') .. '/.local/share/nvim/site'), 
    scandir(os.getenv('DOTFILES') .. '/config/nvim/lua')
  )
end

M.Scripts = function()
  vim.fn['fzf#run']({
    source=getScripts(),
    sink='e'
  })
end

-- require 'pl.pretty'.dump(scandir(os.getenv('HOME') .. '/.local/share/nvim/site') )
-- require 'pl.pretty'.dump(scandir(os.getenv('DOTFILES') .. '/config/nvim/lua'))
return M
