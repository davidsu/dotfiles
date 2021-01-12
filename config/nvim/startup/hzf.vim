"MAPPINGS{{{
"--------------------------------------------------------------------------------
" Mapping selecting mappings
nmap \<tab> <plug>(fzf-maps-n)
xmap \<tab> <plug>(fzf-maps-x)
omap \<tab> <plug>(fzf-maps-o)

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)


nmap 1om :Mru<cr>
nmap 1w :Mrw<cr>
nmap \v :Vimrc<cr>
nmap \a :Ag 
nmap \r :Agraw
"-----------------------------------------------------------------------------}}}
"GLOBALS                                                                      {{{ 
"--------------------------------------------------------------------------------
let g:fzf_launcher = "$DOTFILES/bin/itermFzfVim %s"
let g:fzf_layout = { 'down': '~60%' }
" let g:fzf_command_prefix = 'Fzf'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

"-----------------------------------------------------------------------------}}}
"FUNCTIONS                                                                    {{{ 
"--------------------------------------------------------------------------------
let s:previewsh = '$HOME/.dotfiles/bin/preview.sh' "expand('<sfile>:h:h').'/plugged/fzf.vim/bin/preview.rb'
let s:bin = expand('<sfile>:h:h').'/bin'
    
function! Noop(...)
endfunction

function! FindText(text, ...)
    let additionalParams = ( a:0 > 0 ) ? a:1 : ''
    let agcmd = '-p '''.utils#get_git_root_directory().'/.gitignore'' '.''''.a:text.''' '.additionalParams
    call fzf#vim#ag_raw(agcmd, hzf#defaultPreview())
endfunction

function! FindAssignment(variableName, ...)
    let additionalParams = ( a:0 > 0 ) ? a:1 : ''
    " (?<=...) positive lookbehind: must constain
    " (?=...) positive lookahead: must contai
    let agcmd = '''(=|:).*\b'.a:variableName.'\b'' | ag -v ''\('' '.additionalParams
    " call histadd('cmd', 'Agraw '''''.agcmd.''' -A 0 -B 0''')
    call fzf#vim#ag_raw(agcmd, hzf#defaultPreview())
endfunction

function! FindUsage(variableName, ...)
    let additionalParams = ( a:0 > 0 ) ? a:1 : ''
    let agcmd = '''(?<!function\s)\b'.a:variableName.'(?=\()'' '.additionalParams
    " call histadd('cmd', 'Agraw '''''.agcmd.''' -A 0 -B 0''')
    call fzf#vim#ag_raw(agcmd, hzf#defaultPreview())
endfunction

"-----------------------------------------------------------------------------}}}
"COMMANDS                                                                     {{{
"--------------------------------------------------------------------------------
command! -nargs=+ FindFunction call FindFunction(<args>)
command! -nargs=+ FindAssignment call FindAssignment(<args>)
command! -nargs=+ FindUsage call FindUsage(<args>)
command! -nargs=+ FindText call FindText(<args>)
command! -nargs=+ FindNoTestFunction call FindFunction(<args>, s:ignoreTests)
command! -nargs=+ FindNoTestAssignment call FindAssignment(<args>, s:ignoreTests)
command! -nargs=+ FindNoTestUsage call FindUsage(<args>, s:ignoreTests)
command! -nargs=+ FindNoTestText call FindText(<args>, s:ignoreTests)
command! -nargs=+ FindOnlyTestFunction call FindFunction(<args>, onlyTest)
command! -nargs=+ FindOnlyTestAssignment call FindAssignment(<args>, onlyTest)
command! -nargs=+ FindOnlyTestUsage call FindUsage(<args>, onlyTest)
command! -nargs=+ FindOnlyTestText call FindText(<args>, onlyTest)
command! -nargs=+ Agraw call hzf#ag_raw(<q-args>)

command! ChangeColorScheme :call fzf#run({
    \   'source':
    \     map(split(globpath(&rtp, "colors/*.vim"), "\n"),
    \         "substitute(fnamemodify(v:val, ':t'), '\\..\\{-}$', '', '')"),
    \   'sink':    'colo',
    \   'options': '+m',
    \   'left':    30
    \ })<CR>

command! -bang -nargs=* Ag
    \ call fzf#vim#ag(<q-args>,
    \                 '-p '''.utils#get_git_root_directory().'/.gitignore''',
    \                 hzf#defaultPreview(),
    \                 1)


command! FZFFiles call fzf#run({
    \  'source': 'find -L . | egrep -v \.git',
    \  'sink':    'e',
    \  'options': '-m -x +s'})

let onlyTest=' | ag ''(unit|spec).js'''

let vimhelpignores = 
\'--ignore ''howto*'' '.
\'--ignore ''intro*'' '.
\'--ignore ''edit*'' '.
\'--ignore ''help*'' '.
\'--ignore ''if_*'' '.
\'--ignore ''ft_*'' '.
\'--ignore ''autoc*'' '.
\'--ignore ''change*'' '.
\'--ignore ''gui_*'' '.
\'--ignore ''eval'' '
let vimhelp_default_options = ' --preview-window up:50% --preview "'''.s:previewsh.'''"\ \ {} --bind ''ctrl-g:toggle-preview,ctrl-s:toggle-sort''' 

if exists('$IGNORE_TESTS')
    let s:ignoreTests = $IGNORE_TESTS
else
    let s:ignoreTests = " --ignore '*.spec.js' --ignore '*.unit.js' --ignore '*.it.js' --ignore '*.*.spec.js' --ignore '*.*.*unit.js' --ignore '*.*.*it.js'"
endif

function! FindFunction(functionName, ...)
  let gitRepo = utils#get_git_root_directory()
  let additionalParams = ( a:0 > 0 ) ? a:1 : ''
  " (?<=...) positive lookbehind: must constain
  " (?=...) positive lookahead: must contain
  let agcmd = '''(?<=function\s)'.a:functionName.'(?=\s*\()|'.
        \'\b'.a:functionName.'\s*:|'.
        \'^\s*'.a:functionName.'\([^)]*\)\s*\{\s*$|'.
        \'(?<=prototype\.)'.a:functionName.'(?=\s*=\s*function)|'.
        \'(var|let|const|this\.)\s*'.a:functionName.'(?=\s*=\s*(function|(\([^)]*\)|\w+)\s*=>)\s*)|'.
        \'(public|private)\s+(async\s+)?'.a:functionName.'\(|'.
        \'^\s+async\s+'.a:functionName.'\('.
        \''' -p '''.gitRepo.'/.gitignore'' '.
        \additionalParams

  call fzf#vim#ag_raw(agcmd, hzf#defaultPreview(), 1)
endfunction

command! CommandLineCommands call fzf#vim#ag_raw('--nobreak --noheading '.
            \ vimhelpignores.
            \'''^\s*\|:''', 
            \{'dir':$VIMRUNTIME.'/doc',
            \'options': vimhelp_default_options}, 1)

command! LetterCommands call fzf#vim#ag_raw('--nobreak --noheading '.
            \ vimhelpignores.
            \'''^\|[^-:0-9](\|?|[^:]{0,6}[^)])\|''', 
            \{'dir':$VIMRUNTIME.'/doc',
            \'options': vimhelp_default_options}, 1)

"todo give this sink function (+ preview?)
command! LeaderMappingsDeclaration call hzf#leader_mappings_declarations()
let s:leaderOrAltChars = '[,`¡™£¢∞§¶•ªº≠œ∑´®†¥¨ˆøπ“‘«åß∂ƒ©˙∆˚¬…æΩ≈ç√∫˜µ≤≥÷q]'
command! -nargs=? AgAllBLines call hzf#ag_all_blines(<q-args>)
" command! LeaderMappingsDeclaration call fzf#vim#ag('^\s*[^"\s]*map.*' . s:leaderOrAltChars . '[!-~]*', fzf#vim#with_preview({'dir':'$DOTFILES/config/nvim/startup', 'down': '100%'},'up:30%', 'ctrl-g'))
command! Options call hzf#options()
command! Variables call hzf#variables()
command! Scripts lua require('hzf').Scripts()

"-----------------------------------------------------------------------------}}}
"AUTOCOMMANDS                                                                 {{{
"--------------------------------------------------------------------------------
augroup myfzfgroup
    autocmd!
    " autocmd FileType javascript,typescript,typescript.tsx nnoremap <buffer>gd :normal! m`<cr>:call GoToDeclaration()<cr>
    autocmd FileType javascript,typescript,typescript.tsx nnoremap <buffer>gd :normal! m`<cr>:JSGoToDeclaration<cr>
    autocmd FileType gitcommit nnoremap <buffer>,<Tab> :call FugitiveMappings()<cr>
    autocmd FileType gitcommit nnoremap <buffer>\<Tab> :call FugitiveMappings()<cr>
augroup END
"-----------------------------------------------------------------------------}}}
