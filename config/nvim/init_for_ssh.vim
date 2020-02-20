runtime! debian.vim
source $DOTFILES/config/nvim/plug.vim
call plug#begin('$DOTFILES/config/nvim/plugged')
Plug 'leafgarland/typescript-vim', {'for': 'typescript'}
Plug 'yuttie/comfortable-motion.vim'                               " Brings physics-based smooth scrolling to the Vim world!
Plug 'tommcdo/vim-exchange'                                         " exchange text with cx
Plug 'sudavid4/vim-visual-star-search'                              " extends */# to do what you would expect in visual mode
Plug 'qpkorr/vim-bufkill'                                           " wipe buffer without closing it's window
Plug 'tpope/vim-scriptease'                                         " utilities for vim script authoring. Installed to use ':PP'=pretty print dictionary
Plug 'schickling/vim-bufonly'                                       " delete all buffers but current
Plug 'airblade/vim-rooter'                                          " cd into root of project
Plug 'kshenoy/vim-signature'                                        " help for working with marks
Plug 'sudavid4/vim-plugin-AnsiEsc'                                  " type :AnsiEsc to get colors as terminal
Plug 'blueyed/vim-diminactive' 
Plug 'Konfekt/FastFold'                                             " fold zyntax is too heavy for vim, makes neocomplete very slow. this plugin solves it
Plug 'henrik/vim-indexed-search'                                    " Match 123 of 456 /search term/ in Vim searches
Plug 'junegunn/fzf', { 'dir': '/tmp/fzf', 'do': './install --all' }
Plug 'sudavid4/fzf.vim'                 " fuzzy file finder and so much more
Plug 'dahu/vim-fanfingtastic'                                       " improved f F t T commands
Plug 'airblade/vim-gitgutter'                                       " add git status for each modified line
Plug 'NLKNguyen/papercolor-theme'
Plug 'vim-airline/vim-airline'                                      " fancy statusline
Plug 'sudavid4/vim-airline-themes'                                  " themes for vim-airline
Plug 'tpope/vim-commentary'                                         " comment stuff out
Plug 'sudavid4/vim-unimpaired'                                      " mappings which are simply short normal mode aliases for commonly used ex commands
Plug 'tpope/vim-surround'                                           " mappings to easily delete, change and add such surroundings in pairs, such as quotes, parens, etc.
Plug 'tpope/vim-fugitive'                                           " amazing git wrapper for vim
Plug 'tpope/vim-repeat'                                             " enables repeating other supported plugins with the . command
Plug 'sudavid4/gv.vim'                                              " :GV browse commits like a pro
Plug 'tpope/vim-sleuth'                                             " detect indent style (tabs vs. spaces)
Plug 'sickill/vim-pasta'                                            " fix indentation when pasting
Plug 'gavocanov/vim-js-indent', { 'for': 'javascript' }             " JavaScript indent support
Plug 'othree/yajs.vim', { 'for': ['javascript', 'jsx'] }            " JavaScript syntax plugin
Plug 'maxmellon/vim-jsx-pretty'
Plug 'elzr/vim-json', { 'for': 'json' }                             " JSON support
Plug 'othree/es.next.syntax.vim', { 'for': 'javascript' }           " ES6 and beyond syntax
highlight def link jsxCloseTag javascriptIdentifierName
highlight def link jsxCloseString javascriptIdentifierName
highlight def link jsxTag javascriptIdentifierName
hi link javascriptReserved javascriptVariable
hi link javascriptReservedCase javascriptVariable
call plug#end()

let &runtimepath.=',/tmp/dotfiles/config/nvim'
if !isdirectory($DOTFILES.'/config/nvim/plugged')
    PlugInstall
endif
let file_list = split(globpath("$DOTFILES/config/nvim/startup/", "*.vim"), '\n')

for file in file_list
    if file !~ "Session.vim" && file !~ "plugins.vim" && file !~"deoplete_ultisnip.vim"
     " echom file
    execute( 'source '.file )
endif
endfor
nnoremap <c-t> :silent! call GFilesIfNotHelp()<cr>

nmap \a :Ggrep 
nmap 1n :Sexplore<cr>
nmap - :Sexplore<cr>
