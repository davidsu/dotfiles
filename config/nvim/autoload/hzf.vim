let s:previewrb = utils#get_root_directory().'/plugged/fzf.vim/bin/preview.rb'
"-----------------------------------------------------------------------------}}}
"UTILITIES                                                                      {{{ 
"--------------------------------------------------------------------------------
function! hzf#headerKeyCombinationColor(keyCombination)
    return printf("\e[38;5;43m%s \e[0m", a:keyCombination)
endfunction

function! hzf#defaultPreview()
    return {'options': ' --preview-window up:50% '.
                \'--preview "'''.s:previewrb.'''"\ -v\ {} '.
                \'--header '''.hzf#headerKeyCombinationColor('CTRL-o').' - open without abort :: '.
                \hzf#headerKeyCombinationColor('CTRL-s').' - toggle sort :: '.
                \hzf#headerKeyCombinationColor('CTRL-g').' - toggle preview window'' '. 
                \"--bind 'ctrl-g:toggle-preview,".
                \"ctrl-s:toggle-sort,".
                \"ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'",
                \'down': '100%'}

endfunction
    
function! hzf#defaultGitLogOptions(isBufferOnlyLog)
    let l:header = hzf#headerKeyCombinationColor('CTRL-g').' - toggle preview window :: '.
                \hzf#headerKeyCombinationColor('CTRL-o').' - open this commit in LESS'
    if a:isBufferOnlyLog
        let l:header = l:header.' :: '.hzf#headerKeyCombinationColor("CTRL-d").' - diff with current'
    endif
    return {'options': 
                \" --preview  'sh ".utils#get_bin_directory()."/fzfGitShowFilesForSha.zsh {}' --preview-window 'up:40%' ".
                \"--header '".l:header."' ". 
                \'--bind "ctrl-g:toggle-preview,'.
                \'ctrl-o:execute:sh '.utils#get_bin_directory().'/fzfgitshow.sh {} > /dev/tty"' 
                \  }
endfunction

"-----------------------------------------------------------------------------}}}
"AG                                                                           {{{ 
"--------------------------------------------------------------------------------
function! hzf#ag_all_blines(...)
    let bufs = filter(utils#buffers_listedReadableFile(), 'v:val !~ ''/''')
    let agfiles = '-G '''.join(bufs, '|').''''
    let query = get(a:000, 0, '^')
    if !len(query)
      let query = '^'
    endif
    let query = agfiles.' '''.query.''''
    echom query
    call fzf#vim#ag_raw(query, 
             \fzf#vim#with_preview({'dir': getcwd()},'up:50%', 'ctrl-g'), 1)
endfunction

function! hzf#ag_bLines(...)
    let query = get(a:000, 0, '^')
    if !len(query)
      let query = '^'
    endif
    "We get filename without path, set working directory to dir of the file so filename will be sortest in fzf
    let filename = expand('%:t')
    if len(filename) == 0
        execute('BLines')
        return
    endif
    let query = '-G '.filename.' '.query
    "todo bind ctrl-s isn't working here, looks like someone binds it later on to 'select'
   call fzf#vim#ag_raw(query, 
            \fzf#vim#with_preview({
                                \'dir':expand('%:p:h'), 
                                \'options': ' --header ''ctrl-t: toggleSort'' --bind ctrl-t:toggle-sort,ctrl-s:toggle-sort '},'up:50%', 'ctrl-g'), 1)
endfunction

function! hzf#ag_raw(...)
     call fzf#vim#ag_raw(' '.join(a:000), hzf#defaultPreview(), 1)
endfunction


"-----------------------------------------------------------------------------}}}
"GIT                                                                          {{{ 
"--------------------------------------------------------------------------------
function! hzf#git_log() 
    "second parameter truthy for full screen
    call fzf#vim#commits(hzf#defaultGitLogOptions(0), 1)
endfunction
 
function! hzf#git_log_follow()
    call fzf#vim#buffer_commits(hzf#defaultGitLogOptions(1), 1)
endfunction

"-----------------------------------------------------------------------------}}}
"YANK-RING                                                                    {{{ 
"--------------------------------------------------------------------------------
function! s:yankRingSink(val)
  let boo = substitute(a:val, '^.\{-\}\(\d\)', '\1', '')
  let num = matchstr(boo, '^\S*')
  YRShow
  redraw
  echo num
  execute 'normal '.num
endfunction

function! hzf#yankRing()
  "todo: set this up like GV instead
  "you'll likely get away with binding you stuff straight to the yankring buffer
    call fzf#run({
          \'dir': g:yankring_history_dir,
          \'source': 'cat -n ' . g:yankring_history_file . '_v2.txt | sed -E ''s#,[vV]$##g'' ',
          \'sink': function('s:yankRingSink'),
          \'options': "--preview 'sh ".utils#get_bin_directory()."/tr_002_newline.sh {}' ".
          \'--header '''.hzf#headerKeyCombinationColor('CTRL-s').' - toggle sort :: '.
          \hzf#headerKeyCombinationColor('CTRL-g').' - toggle preview window'' '. 
          \'--preview-window 60%:right '.
          \"--bind 'ctrl-g:toggle-preview,".
          \"ctrl-s:toggle-sort'"
          \})
endfunction

"-----------------------------------------------------------------------------}}}
"OPTIONS/VARIABLES                                                            {{{ 
"--------------------------------------------------------------------------------
function! hzf#variables()
  "todo: need some working on this... the output is terrible
    redir => cout
        silent execute 'let g:'
        silent execute 'let b:'
        silent execute 'let w:'
        silent execute 'let t:'
        silent execute 'let s:'
        silent execute 'let l:'
        silent execute 'let v:'
    redir END
    let list = sort(split(cout, '\n'))
    call fzf#run({
    \  'source':  list,
    \  'sink':    function('Noop') })
endfunction

function! hzf#options()
    redir => cout
        silent execute 'set'
    redir END
    call system('echo '.cout.' > /tmp/o')
    let list = split(substitute(escape(cout, '-'''), '\s\{3,\}', '\n', 'g'), '\n')
    let list = filter(list, 'v:val != '''' && v:val !~ ''Options''')
    let list = map(list, 'substitute(v:val, ''^\W\+'', '''', '''')')
    let list = sort(list)
    call fzf#run({
    \  'source':  list,
    \  'sink':    function('Noop') })
endfunction
