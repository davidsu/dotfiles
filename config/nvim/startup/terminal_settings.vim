function! ClearTermScrollback()
    set scrollback=0
    sleep 100m
    redraw
    set scrollback=1000
endfunction
if has('nvim')
    " Mappings {{{1
    tnoremap \\ <C-\><C-n>
    " stop fg job and rerun last command
    tmap <C-x> <C-c><C-l><C-\><C-n>:call ClearTermScrollback()<cr>i<C-p><cr>
    tnoremap ,, <C-\><C-n>
    tnoremap <C-o> <C-\><C-n>
    tnoremap ,k <C-\><C-n>:wincmd k<cr>
    tnoremap ,j <C-\><C-n>:wincmd j<cr>
    tnoremap <C-h> <C-\><C-n>:setlocal nobuflisted<cr>:wincmd h<cr>
    tnoremap <C-k> <C-\><C-n>:wincmd k<cr>
    tnoremap ,h <C-\><C-n>:wincmd h<cr>
    tnoremap ,l <C-\><C-n>:wincmd l<cr>
    tnoremap <silent><C-l> <C-l><C-\><C-n>:call ClearTermScrollback()<cr>i
    tnoremap ]b <C-\><C-n>:bnext<cr>
    tnoremap [b <C-\><C-n>:bprevious<cr>
    tnoremap ]t <C-\><C-n>:tabnext<cr>
    tnoremap [t <C-\><C-n>:tabprevious<cr>
    "¬ = alt+l
    " tnoremap ¬ loadall<cr>reload<cr>fg[blue]='\033[38;5;111m'<cr>source $DOTFILES/prompt<cr>clear<cr> 
    tnoremap m, <C-\><C-n>:setlocal nobuflisted<cr><c-^>
    tnoremap ,. <C-\><C-n>:setlocal nobuflisted<cr><c-^>
    tnoremap ,ev <C-\><C\n>:source ~/.dotfiles/config/nvim/init.vim<cr> 
    tnoremap ,nt  !'spec.js !'unit.js !'it.js
    tnoremap ,ot 'spec.js \| 'unit.js \| 'it.js
    augroup terminal_group
	au!
	au TermOpen *FZF tmap <buffer> <C-k> <C-k>
	au TermOpen *zsh setlocal nobuflisted | 
		    \nmap <buffer><C-x> :startinsert<cr><C-x> |
		    \nmap <buffer><C-c> :startinsert<cr><C-c>
    augroup END
    " tmap <silent><Esc> <esc><C-\><c-n>
endif
