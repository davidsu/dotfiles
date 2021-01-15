" need to add some environment variables in ~/.local/share/firenvim/firenvim
" export MRU_TXT="$HOME/.local/share/jsMRU.txt"
" export DOTFILES="$HOME/.dotfiles"
" nvim path might be wrong, need to fix this too

if exists('g:started_by_firenvim')
  set shiftwidth=2
  nmap <space>yy :w !pbcopy<cr>:q<cr>
  nnoremap <space>fp :call firenvim#focus_page()<CR>
  nnoremap <C-z> :call firenvim#hide_frame()<CR>
endif
