if exists('*coc#util#float_hide')
    nmap <C-c> <Plug>(coc-float-hide)
endif

fun! WordBelowCursor() abort
    "taken from snipmate source code
    return matchstr(getline('.'), '\S\+\%' . col('.') . 'c')
endf
function! CanExpandUltiSnip()
    " true if there is a snippet named exactly as word under cursor
    return len(filter(keys(UltiSnips#SnippetsInCurrentScope()), 'v:val == '''.WordBelowCursor().'''')) == 1
endfunction
" will expand snippet if possible, else will <c-n> on popupmenu, else will jump to next snippet position(see g:UltiSnipsJumpForwardTrigger)
inoremap <expr><TAB>  CanExpandUltiSnip() ? "\<C-R>=UltiSnips#ExpandSnippetOrJump()<cr>" : pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <c-space> <c-r>=UltiSnips#ExpandSnippet()<cr>
" function! s:my_cr_function()
"     " return (pumvisible() ? "\<C-y>" : "" ) . "\<CR>"
"     " For no inserting <CR> key.
"     return pumvisible() ? "\<C-y>" : "\<CR>"
" endfunction
