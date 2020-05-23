function! DefaultTernHandler(lines)
    " echom 'in DefaultTernHandler'
    " let source = map(a:lines, 'substitute(v:val.filename, getcwd(), '', '').'':''.v:val.lnum')
    " echom string(a:lines)
    let source = map(a:lines, 'substitute(v:val.filename, getcwd().''/'', '''', '''').'':''.v:val.lnum')
    " echom string(source)
    let agcmd = 'ag ''(?<!function\s)\b'.expand('<cword>').'(?=\()'' '
    let agresult = system(agcmd)
    let agreslist = split(agresult, '\n')
    let g:a = agreslist
    let source = extend(source, [repeat('-', 40).'END OF TERN RESULTS'.repeat('-', 70)])
    let source = extend(source, agreslist)
    " echom agresult
    let opts = s:defaultPreview()
    let opts.source = source
    function! opts.sink(lines)
        echom string(a:lines)
        execute('edit '.split(a:lines, ':')[0])
    endfunction
    call fzf#run(opts)
endfunction
function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction
function! DiffFile()
    let winheight = winheight(winnr())
    let branchname=b:branchName
    let filename = substitute(getline('.'), '^\w*\s*\(.*\)', '\1', '')
    let gitroot = b:gitroot
    only
    wincmd s
    execute 'resize '.winheight
    wincmd j
    execute 'cd '.gitroot
    execute 'edit '.filename
    execute 'Gdiff '.branchname
endfunction
function! GDiffBranch(branchName)
    let gitroot = utils#get_git_root_directory()
    let tmpfile = tempname()
    execute 'pedit '.tmpfile
    wincmd P
    let b:branchName=a:branchName
    let b:gitroot = gitroot
    nmap <buffer> q :q<cr>
    execute 'silent read! git diff --name-status '.a:branchName
    normal! ggdd
    resize 12
    setlocal nomodifiable
    nmap <buffer> gd :call DiffFile()<cr>
endfunction
command! -nargs=1 GDiffBranch call GDiffBranch(<q-args>)
function! FormatIndependentJSObject()
	let tmpfile = tempname()
	let lines = s:get_visual_selection()
	execute 'pedit '.tmpfile
	wincmd P
	put='console.log(JSON.stringify('
	put=lines
	put=', null, 4))'
	write
	execute '%!node '.tmpfile
	write
	execute '%! python -m json.tool'
	write
	bd
	normal gv
	normal! "_d
	normal! D
	execute 'read! cat '.tmpfile
	normal! p
endfunction

function! JsToJSON()
    let tmpfile = tempname()
    let contents = join(getline(0, 100000), "\n")
    "edit in preview window
    execute 'pedit '.tmpfile

    "navigate to preview window
    wincmd P

    "convert original contents to formated json
    put!='console.log(JSON.stringify('
    put=contents
    put=', null, 4))'
    write
    execute '%!node %'
    write
    execute '%! python -m json.tool'
    write

    "yank json result to register t
    normal! ggVG"ty

    "wipeout preview window
	bd

    "delete data from original file
    normal! ggVG"_d

    "paste data from register t
    normal! "tp
endfunction

function! ToJSON()
    try
        call json_decode(join(getline(0, 10000)))
        execute '%! python -m json.tool'
        silent w
    catch
        call JsToJSON()
    endtry
endfunction

xnoremap <space>jf :<c-u>silent call FormatIndependentJSObject()<cr>
au! FileType json nnoremap <space>jf :silent call ToJSON()<cr>
command! ToJSON call JsToJSON()
