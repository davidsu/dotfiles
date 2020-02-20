if has('nvim') && exists('*deoplete#custom#source')
    let g:python3_host_prog='/usr/local/bin/python3'
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#sources#ternjs#tern_bin = '/usr/local/bin/tern'
    inoremap <Esc>  <Esc><Esc>
    call deoplete#custom#option({
    \ 'auto_complete_delay': 20,
    \ 'smart_case': v:true,
    \ 'auto_refresh_delay': 120
    \ })

    inoremap <silent><expr> <c-n>
                \ pumvisible() ? "\<C-n>" : 
                \ deoplete#is_enabled() ? deoplete#mappings#manual_complete() :
                \ "\<C-x>\<C-n>"

    " inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
    set completeopt-=preview
    let g:deoplete#omni#functions = {}
    let g:deoplete#omni#functions.javascript = [
             \ 'tern#Complete',
             \]
    let g:deoplete#sources = {}
    let g:deoplete#sources['javascript.jsx'] = ['buffer', 'ultisnips', 'ternjs']
endif

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

let g:tern#command = ['tern']
let g:tern#arguments = ['--persistent']
let g:UltiSnipsExpandTrigger = '<c-space>'
let g:UltiSnipsListSnippets = '<c-b>'
let g:UltiSnipsJumpForwardTrigger = '<C-j>'
let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
let g:UltiSnipsSnippetsDir = $DOTFILES.'/config/nvim/UltiSnip'
let g:UltiSnipsSnippetDirectories = [$DOTFILES.'/config/nvim/UltiSnip']
let g:UltiSnipsEnableSnipMate = 1
if has('nvim') && exists('*deoplete#custom#source')
    au VimEnter * call deoplete#custom#source('ultisnips', 'rank', 1000)
endif
