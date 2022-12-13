function! DiffInWebstorm()
    if &ft =~ 'gitcommit'
        if getline('.') !~ ':'
            echom 'which file to diff?'
            return
        endif
        " set cursor to start of line
        call feedkeys('0')
        " find file name with path
        execute 'silent normal! /\v(\w*(\/|$)(\w|-)*)+'."\r"
        " copy file name to register f
        "execute 
        normal "fy$
        let filename=@f
        " open diff in webstorm
        if len(filename)
            execute '!git difftool -t=webstorm '.filename
        endif
    else
        !git difftool -t=webstorm %
    endif
endfunction

function! JiraCommit()
    normal! gg
    call search('On branch \zs', '', 6)
    let p='$'.substitute(getline('.'), '.*On branch\s*\(.\{-}-.\{-}\)\( \|-\|$\).*', '\1', '').'|'
    0put=p
    call feedkeys('A')
    " normal "fyW
    " 0put='$'
    " normal "fp0f-lwD
    " call feedkeys('a|')
endfunction
augroup fugitiveautocmd
	autocmd!
	autocmd FileType fugitive nmap <buffer> <silent>q :q<cr>
    autocmd FileType fugitive nmap <buffer> <space>gd <C-w><C-o>dd
    autocmd FileType fugitive nmap <buffer>gd <C-w><C-o>dd
    autocmd FileType git nnoremap <buffer>q :wincmd q<cr>
    " autocmd BufEnter *.git/COMMIT_EDITMSG silent! normal zMGzogg
    autocmd FileType gitcommit nmap <buffer> ]c <C-n>
    autocmd FileType gitcommit nmap <buffer> [c <C-p>
    autocmd FileType gitcommit nmap <buffer> <space>jc :call JiraCommit()<cr>
augroup END
command! DiffInWebstorm !git difftool -t=webstorm %

