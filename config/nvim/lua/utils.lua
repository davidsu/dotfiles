local M = {}

M.isModuleAvailable = function (name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

M.hasPacker = function()
  return vim.loop.fs_stat(os.getenv('HOME') .. '/.local/share/nvim/site/pack/packer/start/packer.nvim')
end

_G.dump = function(table) 
  print(require 'pl.pretty'.dump(table))
end

return M
