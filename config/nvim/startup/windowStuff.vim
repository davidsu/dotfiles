function! HorizontalResize(key)
	let l:winheight = winheight(0)
	if(a:key == '+')
		exec '5wincmd +'
	else
		exec '5wincmd -'
	endif
	if(l:winheight == winheight(0))
		let g:forcehorizontalresize = 0
	endif
endfunction
function! WinSize(key)
	if(g:forcehorizontalresize)
		call HorizontalResize(a:key)
		return
	endif
	let t:curwin = winnr()
	exec "wincmd l"
	if (t:curwin == winnr())
		exec "wincmd h"
		if (t:curwin == winnr())
			call HorizontalResize(a:key)
			return
		endif
		exec "wincmd l"
	else
		exec "wincmd h"
	endif
	if(a:key == '+')
		exec '5wincmd >'
	else
		exec '5wincmd <'
	endif
endfunction

function! ToggleForceVerticalResize()
	if(g:forcehorizontalresize)
		let g:forcehorizontalresize = 0
	else
		let g:forcehorizontalresize = 1
	endif
	" sleep 800m
	" let g:forcehorizontalresize = 0
endfunction
" increase decrease vertica split by +,_
let g:forcehorizontalresize = 0
nnoremap + :call WinSize('+')<cr><esc>
nnoremap _ :call WinSize('-')<cr>
nnoremap <space>v :call ToggleForceVerticalResize()<cr>
"invert split resizing
nnoremap <space>is :call ToggleForceVerticalResize()<cr>
nnoremap \x :call ToggleForceVerticalResize()<cr>
"'≠' == 'alt+=', '–' == 'alt+-', º == 'alt+0'
nnoremap ≠ :call WinSize('+')<cr>
nnoremap – :call WinSize('-')<cr>
nnoremap º :call ToggleForceVerticalResize()<cr>
if has('nvim')
  tnoremap ≠ <C-\><C-n>:call WinSize('+')<cr>i
  tnoremap – <C-\><C-n>:call WinSize('-')<cr>i
  tnoremap º <C-\><C-n>:call ToggleForceVerticalResize()<cr>i
endif

nnoremap <silent> <C-j> :wincmd j<cr>
nnoremap <silent> <C-k> :wincmd k<cr>
nnoremap <silent> <C-l> :wincmd l<cr>
nnoremap <silent> <C-h> :wincmd h<cr>
nnoremap <silent> <C-p> :wincmd p<cr>

function! HtmlUnEscape()
  silent s/&lt;/</eg
  silent s/&gt;/>/eg
  silent s/&amp;/\&/eg
endfunction
