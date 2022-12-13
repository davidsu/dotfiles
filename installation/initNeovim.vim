for i in nvim_get_runtime_file('parser', v:true)
  echom i
  if i =~ '.*neovim.*lib/nvim/parser'
    echom 'deleting bad treesitter parsers: ' . i
    call delete(i, 'rf')
  endif
endfor

au User PackerComplete quit
source $HOME/.dotfiles/config/nvim/lua/plugins.lua
lua require("packer").install()
