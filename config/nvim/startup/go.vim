function! s:goSetup()
    nnoremap <buffer>gd :GoDef<cr>
endfunction
augroup golang
    autocmd!
    autocmd FileType go call <SID>goSetup()
augroup END
