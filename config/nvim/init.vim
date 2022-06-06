" vim: foldmethod=marker
autocmd!
" Load startup files{{{1--------------------------------------------------------------------------------------------------
"-------------------------------------------------------------------------------------------------------------------------
if($DEBUG_COC)
    let g:coc_node_args = ['--nolazy', '--inspect-brk']
endif
" if filereadable($HOME.'/.nvm/versions/node/v14.15.3/bin/node')
if filereadable($HOME.'/Library/Caches/fnm_multishells/72876_1652339420691/bin/node')
    let g:coc_node_path = $HOME.'/Library/Caches/fnm_multishells/72876_1652339420691/bin/node'
endif

function! SourceMyScripts()
    let file_list = split(globpath("$DOTFILES/config/nvim/startup/", "*.vim"), '\n')

    for file in file_list
        if file !~ "Session.vim" && file !~ "plugins.vim"
            " echom file
            execute( 'source '.file )
        endif
    endfor
endfunction
call SourceMyScripts()
lua require('init')

let g:nvcode_termcolors=256
colorscheme darktooth
" let base16colorspace=256  " Access colors present in 256 colorspace"
" colorscheme base16-darktooth
" }}}----------------------------------------------------------------------------------------------------------------------


" source $DOTFILES/config/nvim/startup/plugins.vim
" source $DOTFILES/config/nvim/startup/abbrev.vim
" source $DOTFILES/config/nvim/startup/airline.vim
" source $DOTFILES/config/nvim/startup/custom_fold.vim
" source $DOTFILES/config/nvim/startup/deoplete.vim
" source $DOTFILES/config/nvim/startup/foldsearch.vim
" source $DOTFILES/config/nvim/startup/gitstatus.vim
" source $DOTFILES/config/nvim/startup/javascript.vim
" source $DOTFILES/config/nvim/startup/leader_mappings.vim
" source $DOTFILES/config/nvim/startup/limelight.vim
" source $DOTFILES/config/nvim/startup/misc.vim
" source $DOTFILES/config/nvim/startup/options.vim
" source $DOTFILES/config/nvim/startup/syntastic_config.vim
" source $DOTFILES/config/nvim/startup/tab_titles.vim
" source $DOTFILES/config/nvim/startup/tabname.vim
" source $DOTFILES/config/nvim/startup/terminal_settings.vim
" source $DOTFILES/config/nvim/startup/tmp_stuff.vim
" source $DOTFILES/config/nvim/startup/windowStuff.vim

" source $DOTFILES/config/nvim/startup/fzf.vim
