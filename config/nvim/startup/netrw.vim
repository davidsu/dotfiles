"make netrw view tree by default
let g:netrw_liststyle=3
let g:netrw_banner = 0
let g:netrw_altfile = 1
augroup netrw
    autocmd!
    autocmd FileType netrw nnoremap <buffer>\q :bd<cr>
    autocmd FileType netrw nnoremap <buffer><c-q> :bd<cr>
    autocmd FileType netrw nnoremap <buffer> <nowait> q :bd<cr>
    autocmd FileType netrw nmap <buffer> <silent> <nowait> <bs>  <Plug>NetrwTreeSqueeze
    autocmd FileType netrw set bufhidden=wipe
augroup END
