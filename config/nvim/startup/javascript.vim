"--------------------------------------------------------------------------------
"MAPPINGS{{{
"--------------------------------------------------------------------------------
function! s:setmapping()
    " Moving back and forth between lines of same or lower indentation.
    " nnoremap <buffer><silent> [l :call indent_utils#next_indent(0, 0, 0, 1)<CR>
    " nnoremap <buffer><silent> ]l :call indent_utils#next_indent(0, 1, 0, 1)<CR>
    nnoremap <buffer><silent> [[ m`:call indent_utils#prev_indent()<CR>
    nnoremap <buffer><silent> ]] m`:call indent_utils#next_indent()<CR>
    " vnoremap <buffer><silent> [l <Esc>:call indent_utils#next_indent(0, 0, 0, 1)<CR>m'gv''
    " vnoremap <buffer><silent> ]l <Esc>:call indent_utils#next_indent(0, 1, 0, 1)<CR>m'gv''
    vnoremap <buffer><silent> [[ <Esc>:call indent_utils#prev_indent()<CR>m'gv''
    vnoremap <buffer><silent> ]] <Esc>:call indent_utils#next_indent()<CR>m'gv''
    " onoremap <buffer><silent> [l :call indent_utils#next_indent(0, 0, 0, 1)<CR>
    " onoremap <buffer><silent> ]l :call indent_utils#next_indent(0, 1, 0, 1)<CR>
    onoremap <buffer><silent> [[ :call indent_utils#prev_indent()<CR>
    onoremap <buffer><silent> ]] :call indent_utils#next_indent()<CR>
endfunction

"--------------------------------------------------------------------------------
"FUNCTIONS{{{
"--------------------------------------------------------------------------------

function! RunNeomakeEslint()
    if (&ft =~ '\(java\|type\)script' && (filereadable(get(b:, 'neomake_typescript_eslint_exe')) || filereadable(get(b:, 'neomake_javascript_eslint_exe'))))
        Neomake
    endif
endfunction

command! FixEslint let g:is_running_fixlint = 1 | Neomake fixlint
command! FixLint let g:is_running_fixlint = 1 | Neomake fixlint
function! GetCurrLineIndentation()
    return len(substitute(getline('.'), '\(\s*\).*', '\1', '')) 
endfunction

function! GoToNextFunction(originalLineIndentation, recurseCount, searchBackward)
    echo 'GoToNextFunction - recurseCount = '.a:recurseCount
    set nohlsearch
    let originalLineIndentation = a:originalLineIndentation
    if a:recurseCount > 8
        return
    endif
    let flags = 'eW'
    if originalLineIndentation == -1
        let originalLineIndentation = GetCurrLineIndentation()
        let flags = 'eWs'
    endif
    if a:searchBackward == 1
        let flags = 'b'.flags
    endif
    let functionLineRegex = 'function\s*\w*(.*{'
    let blockStartLineRegex = '\w*([^)]*)\s*{'
    call search(functionLineRegex.'\|'.blockStartLineRegex, flags)
    let currLine = getline('.')
    if (GetCurrLineIndentation() > originalLineIndentation) && (originalLineIndentation > 0)
        call GoToNextFunction(originalLineIndentation, a:recurseCount + 1, a:searchBackward)
    else
        call feedkeys("zz")
	if getpos('.')[1] > 20
	    call feedkeys("\<c-e>\<c-e>\<c-e>")
	endif
    endif
endfunction

" function! JSToggleFoldMethod()
"     if &foldmethod=='syntax' 
"         set foldmethod=manual 
"     else 
"         set foldmethod=syntax 
"     endif
" endfunction

function! TernRestartServer()
    py3 tern_killServers()
    if filereadable(getcwd() . '.tern-port')
        system('rm '.getcwd().'/.tern-port')
    endif
endfunction
command! TernRestartServer call TernRestartServer()
"-----------------------------------------------------------------------------}}}
"AUTOCOMMANDS                                                                 {{{
"--------------------------------------------------------------------------------
augroup javascript
    autocmd!
    " autocmd FileType javascript silent! call LimeLightExtremeties()
    autocmd BufNewFile,BufRead *.js,*.jsx set filetype=typescript
    let g:markdown_fenced_languages = ['css', 'javascript', 'js=javascript', 'json=javascript', 'stylus', 'html']
    autocmd BufWritePost * call RunNeomakeEslint()
    autocmd FileType javascript,json call <SID>setmapping()
    autocmd FileType javascript nnoremap <buffer>{ :call GoToNextFunction(-1, 0, 1)<cr>
    autocmd FileType javascript nnoremap <buffer>} :call GoToNextFunction(-1, 0, 0)<cr>
    " autocmd FileType javascript nnoremap <buffer>cof :call JSToggleFoldMethod()<cr>
    " autocmd Filetype javascript vnoremap <buffer>1= :<C-u>setf jsx<cr>gv=:<C-u>setf javascript<cr>
augroup END
"-----------------------------------------------------------------------------}}}
