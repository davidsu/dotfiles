" http://stackoverflow.com/questions/3131393/remapping-help-in-vim-to-open-in-a-new-tab
function! s:abbrev(shortcut, expansion)
    execute "cnoreabbrev <expr> ".a:shortcut." getcmdtype() == ':' && getcmdline() == '".a:shortcut."' ? '".a:expansion."' : '".a:shortcut."'"
endfunction
cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'
cnoreabbrev <expr> ag getcmdtype() == ":" && getcmdline() == 'ag' ? 'Ag ' : 'ag'
cnoreabbrev <expr> agr getcmdtype() == ":" && getcmdline() == 'agr' ? 'Agraw ''' : 'agr'
cnoreabbrev <expr> bc getcmdtype() == ":" && getcmdline() == 'bc' ? 'BCommits' : 'bc'
cnoreabbrev <expr> mru getcmdtype() == ":" && getcmdline() == 'mru' ? 'Mru' : 'mru'
cnoreabbrev <expr> mrw getcmdtype() == ":" && getcmdline() == 'mrw' ? 'Mrw' : 'mrw'
cnoreabbrev <expr> cdc getcmdtype() == ":" && getcmdline() == 'cdc' ? 'CDC' : 'cdc'
cnoreabbrev <expr> cdr getcmdtype() == ":" && getcmdline() == 'cdr' ? 'CDR' : 'cdr'
cnoreabbrev <expr> cdg getcmdtype() == ":" && getcmdline() == 'cdg' ? 'CDG' : 'cdg'
cnoreabbrev <expr> pp getcmdtype() == ":" && getcmdline() == 'pp' ? 'PP' : 'pp'
cnoreabbrev <expr> t getcmdtype() == ":" && getcmdline() == 't' ? 'GFiles!' : 't'
call s:abbrev('gdb', 'GDiffBranch')
call s:abbrev('man', 'tab Man')
call s:abbrev('cdg', 'CDG')
call s:abbrev('cdc', 'CDC')
call s:abbrev('cc', 'CocCommand ')
call s:abbrev('cl', 'CocList')
call s:abbrev('con', 'CocConfig')

" set wildcharm=<C-Z>
function! s:wildMapper(shortcut, expansion)
    execute 'cnoremap <expr> '.a:shortcut.' wildmenumode() ? "\'.a:expansion.'" : "\'.a:shortcut.'"'
endfunction
call s:wildMapper('<C-j>', '<right>')
call s:wildMapper('<C-k>', '<left>')
"
"https://github.com/houtsnip/vim-emacscommandline/blob/master/plugin/emacscommandline.vim
cmap <C-a> <Home>
cnoremap <c-l> <C-\>e<SID>ForwardWord()<CR>
function! <SID>ForwardWord()
    let l:loc = strpart(getcmdline(), 0, getcmdpos() - 1)
    let l:roc = strpart(getcmdline(), getcmdpos() - 1)
    if (l:roc =~ '\v^\s*\w')
        let l:rem = matchstr(l:roc, '\v^\s*\w+')
    elseif (l:roc =~ '\v^\s*[^[:alnum:]_[:blank:]]')
        let l:rem = matchstr(l:roc, '\v^\s*[^[:alnum:]_[:blank:]]+')
    else
        call setcmdpos(strlen(getcmdline()) + 1)
        return getcmdline()
    endif
    call setcmdpos(strlen(l:loc) + strlen(l:rem) + 1)
    return getcmdline()
endfunction

cnoremap <c-h> <C-\>e<SID>BackwardWord()<CR>
function! <SID>BackwardWord()
    let l:loc = strpart(getcmdline(), 0, getcmdpos() - 1)
    let l:roc = strpart(getcmdline(), getcmdpos() - 1)
    if (l:loc =~ '\v\w\s*$')
        let l:rem = matchstr(l:loc, '\v\w+\s*$')
    elseif (l:loc =~ '\v[^[:alnum:]_[:blank:]]\s*$')
        let l:rem = matchstr(l:loc, '\v[^[:alnum:]_[:blank:]]+\s*$')
    else
        call setcmdpos(1)
        return getcmdline()
    endif
    let @c = l:rem
    call setcmdpos(strlen(l:loc) - strlen(l:rem) + 1)
    return getcmdline()
endfunction

