"help for fzf related stuff
let s:previewrb = utils#get_root_directory().'/plugged/fzf.vim/bin/preview.rb'
let g:fzf_preview_window = ['up:40%:hidden', 'ctrl-/']
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
                \hzf#headerKeyCombinationColor('CTRL-g').' - toggle preview window :: '. 
                \hzf#headerKeyCombinationColor('CTRL-l').' - select all(when multi enabled)'' '. 
                \"--bind 'ctrl-g:toggle-preview,".
                \"ctrl-s:toggle-sort,".
                \"ctrl-l:select-all,".
                \"ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'",
                \'down': '100%'}

endfunction

function! hzf#defaultGitLogOptions(isBufferOnlyLog)
    let l:header = hzf#headerKeyCombinationColor('CTRL-g').' - toggle preview window :: '.
                \hzf#headerKeyCombinationColor('CTRL-o').' - open this commit in LESS'
    if a:isBufferOnlyLog
        let l:header = l:header.' :: '.hzf#headerKeyCombinationColor("CTRL-d").' - diff with current'
    endif
    let options = " --preview  'sh ".utils#get_bin_directory()."/fzfGitShowFilesForSha.zsh {}' --preview-window 'up:40%' ".
                    \"--header '".l:header."' ". 
                    \'--bind "ctrl-g:toggle-preview,'.
                    \'ctrl-o:execute:sh '.utils#get_bin_directory().'/fzfgitshow.sh {} > /dev/tty"' 
    if !a:isBufferOnlyLog
        let options = options.' --bind "ctrl-d:execute:sh '.utils#get_bin_directory().'/githubcommit.sh {}"'
    endif
    let retval = {'options': options }
    return retval
endfunction

"-----------------------------------------------------------------------------}}}
"AG                                                                           {{{ 
"--------------------------------------------------------------------------------
function! hzf#ag_all_blines(...)
    let bufs = filter(utils#buffers_listedReadableFile(), 'v:val !~ ''^/''')
    let agfiles = '-G '''.join(bufs, '|').''''
    let query = get(a:000, 0, '^')
    if !len(query)
        let query = '^'
    endif
    let query = agfiles.' '''.query.''''
    call fzf#vim#ag_raw(query, 
                \fzf#vim#with_preview({'dir': getcwd()},'up:50%', 'ctrl-g'), 1)
endfunction

function! hzf#ag_raw(...)
    call fzf#vim#ag_raw(' '.join(a:000), hzf#defaultPreview(), 1)
endfunction

function! s:sink_leader_mapping(fzfretval)
    let fname = a:fzfretval
    let fname = substitute(fname, '\S\+\s\+\([^:]*\).*', '\1', '')
    let fnum = substitute(a:fzfretval, '.\{-\}:\(\d\+\):.*', '\1', '')
    execute 'e +'.fnum.' $DOTFILES/config/nvim/startup/'.fname	
endfunction

function! hzf#leader_mappings_declarations()
    call fzf#run({
                \'source': 'cd $DOTFILES/config/nvim/startup; sh '.utils#get_bin_directory().'/leader_mappings_declaration.sh', 
                \'sink': function('s:sink_leader_mapping'),
                \'options': '--ansi --bind ''ctrl-s:toggle-sort'' '.
                \'--preview "'''.s:previewrb.'''"\ -v\ $DOTFILES/config/nvim/startup/{2} '.
                \'--preview-window up:40%'
                \})
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

let s:fpath_start = ''
function! s:sink_gfiles(fname)
    execute 'edit '.s:fpath_start.a:fname[0]
endfunction

function! hzf#g_files()
    let groot = utils#get_git_root_directory()
    let args = ''
    if groot == getcwd()
        let s:fpath_start = ''
        GFiles!
        return
    endif
    let s:fpath_start = substitute(getcwd(), groot.'/', '', '').'/'
    let args = ' | grep '''.s:fpath_start.''' | sed ''s#^'.s:fpath_start.'##'' '
    call fzf#run({
                \ 'source':  'git ls-files '.args,
                \ 'dir':     groot,
                \ 'options': '--prompt "GitFiles> "',
                \ 'sink*': function('s:sink_gfiles')
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

