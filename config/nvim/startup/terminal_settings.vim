function! ClearTermScrollback()
    set scrollback=0
    sleep 100m
    redraw
    set scrollback=1000
endfunction
if has('nvim')
    " Mappings {{{1
    " stop fg job and rerun last command
    tmap <C-x> <C-c><C-l><C-\><C-n>:call ClearTermScrollback()<cr>i<C-p><cr>
    tnoremap <C-q> <C-\><C-n>:wincmd q<cr>
    tnoremap <C-o> <C-\><C-n>
    tnoremap <C-h> <C-\><C-n>:setlocal nobuflisted<cr>:wincmd h<cr>
    tnoremap <C-k> <C-\><C-n>:wincmd k<cr>
    tnoremap <silent><C-l> <C-l><C-\><C-n>:call ClearTermScrollback()<cr>i
    "¬ = alt+l
    " tnoremap ¬ loadall<cr>reload<cr>fg[blue]='\033[38;5;111m'<cr>source $DOTFILES/prompt<cr>clear<cr> 
    tnoremap m, <C-\><C-n>:setlocal nobuflisted<cr><c-^>
    augroup terminal_group
	au!
	au TermOpen *FZF tmap <buffer> <C-k> <C-k>
	au TermOpen *FZF tmap <buffer> <C-o> <C-o>
	au TermOpen *zsh setlocal nobuflisted | 
		    \nmap <buffer><C-x> :startinsert<cr><C-x> |
		    \nmap <buffer><C-c> :startinsert<cr><C-c>
    augroup END
    " tmap <silent><Esc> <esc><C-\><c-n>
endif
