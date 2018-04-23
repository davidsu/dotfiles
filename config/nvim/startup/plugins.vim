call plug#begin('~/.config/nvim/plugged')
Plug 'junegunn/vim-peekaboo'
Plug 'leafgarland/typescript-vim', {'for': 'typescript'}
Plug 'sudavid4/comfortable-motion.vim'                               " Brings physics-based smooth scrolling to the Vim world!
Plug 'tweekmonster/startuptime.vim', {'on': 'StartupTime'}  
Plug 'tommcdo/vim-exchange'                                         " exchange text with cx
Plug 'sudavid4/vim-visual-star-search'                              " extends */# to do what you would expect in visual mode
Plug 'SirVer/ultisnips'
Plug 'qpkorr/vim-bufkill'                                           " wipe buffer without closing it's window
Plug 'tpope/vim-scriptease'                                         " utilities for vim script authoring. Installed to use ':PP'=pretty print dictionary
Plug 'idbrii/vim-mark'                                              " highlighting of interesting words
Plug 'sudavid4/mysql-mru.vim'
Plug 'schickling/vim-bufonly'                                       " delete all buffers but current
Plug 'terryma/vim-expand-region'
Plug 'sbdchd/neoformat', { 'for':                           
            \['javascript', 'css', 'scss', 
            \'sh', 'zsh', 'vim', 'html'] , 
            \'do': 'npm -g install js-beautify'}                    " A (Neo)vim plugin for formatting code. - you will need jsbeautifier globally installed
Plug 'junegunn/vim-xmark' , { 'do': 'make', 'for': 'markdown'}      " ❌ Markdown preview on OS X
" I don't know how to use this.... need to learn
Plug 'junegunn/vim-easy-align'                                      " A Vim alignment plugin
Plug 'airblade/vim-rooter'                                          " cd into root of project
Plug 'kshenoy/vim-signature'                                        " help for working with marks
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}                 " markdown
Plug 'godlygeek/tabular', {'for': 'markdown'}                       " related to vim-markdown
Plug 'sudavid4/vim-plugin-AnsiEsc'                                  " type :AnsiEsc to get colors as terminal
Plug 'blueyed/vim-diminactive' 
Plug 'sudavid4/tern_for_vim', {'for': 'javascript', 'do': 'npm i' } " intellijent navigation and refactor for javascript
if(has('nvim'))
    Plug 'Shougo/deoplete.nvim'
    Plug 'Shougo/neco-vim', {'for': 'vim'}                          " deoplete source for vimscript
    Plug 'zchee/deoplete-zsh', {'for': 'zsh'}                       " deoplete source for zsh
    Plug 'sudavid4/deoplete-ternjs', { 'for': 'javascript'}         " deoplete source for javascript
else
    Plug 'Shougo/neocomplete.vim', 
                \{ 'for': ['javascript', 'css', 'scss', 'sh', 'vim', 'html'] }
endif
Plug 'Konfekt/FastFold'                                             " fold zyntax is too heavy for vim, makes neocomplete very slow. this plugin solves it
Plug 'henrik/vim-indexed-search'                                    " Match 123 of 456 /search term/ in Vim searches
Plug '/usr/local/opt/fzf' | Plug 'sudavid4/fzf.vim'                 " fuzzy file finder and so much more
Plug 'sudavid4/neomake-local-eslint.vim', 
            \{ 'for': 'javascript' }                                " let neomake know how to find local eslint
Plug 'benekastah/neomake', 
            \{ 'for': ['javascript', 'rt', 'html'] }                " neovim replacement for syntastic using neovim's job control functonality
Plug 'dahu/vim-fanfingtastic'                                       " improved f F t T commands
Plug 'airblade/vim-gitgutter'                                       " add git status for each modified line
Plug 'sudavid4/base16-vim'
Plug 'kchmck/vim-coffee-script', {'for': 'coffee'}
Plug 'NLKNguyen/papercolor-theme'
Plug 'vim-airline/vim-airline'                                      " fancy statusline
Plug 'sudavid4/vim-airline-themes'                                  " themes for vim-airline
Plug 'sudavid4/vim-js-goToDeclaration', {'for': 'javascript'}       " better ternjs gotodeclaration
if isdirectory(expand('%:p'))
    Plug 'sudavid4/nerdtree'
else
    Plug 'sudavid4/nerdtree' ,{'on': ['NERDTreeFind', 'NERDTreeToggle']}
endif
Plug 'tiagofumo/vim-nerdtree-syntax-highlight' 
Plug 'ryanoasis/vim-devicons', {'on': ['NERDTreeFind', 'NERDTreeToggle']} " file drawer
set guifont=Droid\ Sans\ Mono\ for\ Powerline\ Nerd\ Font\ Complete
Plug 'tpope/vim-commentary'                                         " comment stuff out
Plug 'sudavid4/vim-unimpaired'                                      " mappings which are simply short normal mode aliases for commonly used ex commands
Plug 'tpope/vim-surround'                                           " mappings to easily delete, change and add such surroundings in pairs, such as quotes, parens, etc.
Plug 'tpope/vim-fugitive'                                           " amazing git wrapper for vim
Plug 'tpope/vim-rhubarb'                                            " for `:Gbrowse`
Plug 'tpope/vim-repeat'                                             " enables repeating other supported plugins with the . command
Plug 'haya14busa/incsearch.vim'                                     " Improved incremental searching for Vim
Plug 'sudavid4/gv.vim'                                              " :GV browse commits like a pro
Plug 'tpope/vim-sleuth'                                             " detect indent style (tabs vs. spaces)
Plug 'sickill/vim-pasta'                                            " fix indentation when pasting
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }                " focus tool. Good for presentating with vim
Plug 'mattn/emmet-vim', { 'for': 'html' }                           " emmet support for vim - easily create markdup wth CSS-like syntax
Plug 'alvan/vim-closetag'
Plug 'othree/html5.vim', { 'for': 'html' }                          " html5 support
Plug 'gavocanov/vim-js-indent', { 'for': 'javascript' }             " JavaScript indent support
if expand('%:p') !~ '.git/index$'
    " yajs started making my vim annoyingly slow... going with pangloss for this reason
    " Plug 'othree/yajs.vim', { 'for': ['javascript', 'jsx'] }            " JavaScript syntax plugin
    Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'jsx'] }
endif
Plug 'maxmellon/vim-jsx-pretty'
Plug 'elzr/vim-json', { 'for': 'json' }                             " JSON support
Plug 'othree/es.next.syntax.vim', { 'for': 'javascript' }           " ES6 and beyond syntax
" Plug 'Quramy/tsuquyomi', { 'for': 'typescript', 'do': 'npm install' } " extended typescript support - works as a client for TSServer
" Plug 'leafgarland/typescript-vim', { 'for': 'typescript' } " typescript support
Plug 'cakebaker/scss-syntax.vim', { 'for': 'scss' }                 " sass scss syntax support
Plug 'wavded/vim-stylus', { 'for': ['stylus', 'markdown'] }         " markdown support
Plug 'ap/vim-css-color', { 'for': ['css','stylus','scss'] }         " set the background of hex color values to the color
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }                     " CSS3 syntax support
" Plug 'dhruvasagar/vim-table-mode'

highlight def link jsxCloseTag javascriptIdentifierName
highlight def link jsxCloseString javascriptIdentifierName
highlight def link jsxTag javascriptIdentifierName
hi link javascriptReserved javascriptVariable
hi link javascriptReservedCase javascriptVariable
call plug#end()
