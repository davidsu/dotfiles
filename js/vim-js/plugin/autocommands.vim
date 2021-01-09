function! s:_mruIgnore(fileName)
  if &ft == 'gitconfig'
    return 0
  endif
  if &ft =~? 'git' ||
        \ &ft =~? 'coc-explorer' ||
        \ &ft =~? 'help' ||
        \ &ft =~? 'fzf' ||
        \ expand('%') =~ '/private/var/folders/' || 
        \ expand('%') =~ 'nvim.runtime' ||
        \ expand('%') =~? 'fugitiveblame' ||
        \ expand('%') =~? '/var/folders/.*nvim' ||
        \ expand('%') =~? '\.git/index' ||
        \ !filereadable(a:fileName)
    return 1
  endif
  return 0
endfunction


function! s:sinkMru(selectedFile)
  let args = split(a:selectedFile, ':')
  let file = args[0]
  let line = args[1]
  let column = args[2]
  execute 'edit '.file
  call cursor(line, column)
  normal! zz
  if exists('*CursorPing')
    call CursorPing()
  endif
endfunction

let s:previewrb = '$HOME/.dotfiles/bin/preview.rb'
function! s:viewMru()
  call fzf#run({
        \  'source': 'wget -q -O - http://localhost:2021 ', 
        \  'sink':    function('s:sinkMru'),
        \  'options': '--no-sort --exact  --preview-window up:50% '.
        \'--preview "'''.s:previewrb.''' -v {1}" '.
        \'--header ''CTRL-o - open without abort(LESS) :: CTRL-s - toggle sort :: CTRL-g - toggle preview window'' '.
        \'--bind ''ctrl-g:toggle-preview,'.
        \'ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'''})
endfunction


function! s:saveMru(event)
  if s:_mruIgnore(expand('%:p'))
    return
  endif
  let pos = getpos('.')
  let line = pos[1]
  let column = pos[2]
  let filepath = escape(expand('%:p'), '$')
  let curl = "curl http://localhost:2021/mru "
        \."--header 'Content-Type: application/json' "
        \.'--request POST '
        \.'--data '''
        \.'{'
        \.'"line":'.line.', '
        \.'"column": '.column.', '
        \.'"filepath": "'.filepath.'",'
        \.'"event": "'.a:event.'"'
        \.'}'' &'
  call system(curl)
endfunction

nmap 1m :call <SID>viewMru()<cr>
augroup mrujs
  autocmd!
  autocmd BufReadPost * call s:saveMru('BufReadPost')
  autocmd BufHidden * call s:saveMru('BufHidden')
  autocmd BufWinEnter * call s:saveMru('BufWinEnter')
  autocmd WinEnter * call s:saveMru('WinEnter')
  autocmd VimLeave * call s:saveMru('VimLeave')
augroup END
