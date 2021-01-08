if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

function! SetupDebugger(...)
    if !a:0
        call plug#begin('~/.config/nvim/plugged')
        Plug 'puremourning/vimspector'
        call plug#end()
    else
        Plug 'puremourning/vimspector'
    endif
    autocmd! User VimspectorTerminalOpened :CocCommand vim-js.vimspector.start
endfunction

call plug#begin('~/.config/nvim/plugged')
if $vimdebugger
  call SetupDebugger(1)
endif

Plug $DOTFILES.'/js/vim-js'
" Plug 'tommcdo/vim-fubitive'
Plug 'ssh://git@git.walkmedev.com:7999/~david.susskind/walkme-vim-gbrowse.git'
" Plug 'matthewtodd/vim-fustashtive'
" Plug 'junegunn/vim-peekaboo'
Plug 'leafgarland/typescript-vim', {'for': ['typescript', 'typescript.tsx']}
Plug 'davidsu/comfortable-motion.vim'                               " Brings physics-based smooth scrolling to the Vim world!
Plug 'tweekmonster/startuptime.vim', {'on': 'StartupTime'}  
Plug 'tommcdo/vim-exchange'                                         " exchange text with cx
Plug 'davidsu/vim-visual-star-search'                              " extends */# to do what you would expect in visual mode
Plug 'SirVer/ultisnips'
Plug 'davidsu/vim-bufkill'                                           " wipe buffer without closing it's window
Plug 'tpope/vim-scriptease'                                         " utilities for vim script authoring. Installed to use ':PP'=pretty print dictionary
Plug 'inkarkat/vim-ingo-library'                                    "dependency of vim-mark
Plug 'idbrii/vim-mark'                                              " highlighting of interesting words
Plug 'schickling/vim-bufonly'                                       " delete all buffers but current
Plug 'terryma/vim-expand-region'
" Plug 'sbdchd/neoformat', { 'for':                           
"             \['javascript', 'css', 'scss', 
"             \'sh', 'zsh', 'vim', 'html'] , 
"             \'do': 'npm -g install js-beautify'}                    " A (Neo)vim plugin for formatting code. - you will need jsbeautifier globally installed
Plug 'junegunn/vim-xmark' , { 'do': 'make', 'for': 'markdown'}      " ❌ Markdown preview on OS X
" I don't know how to use this.... need to learn
Plug 'junegunn/vim-easy-align'                                      " A Vim alignment plugin
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}                 " markdown
Plug 'godlygeek/tabular', {'for': 'markdown'}                       " related to vim-markdown
Plug 'davidsu/vim-plugin-AnsiEsc'                                  " type :AnsiEsc to get colors as terminal
Plug 'blueyed/vim-diminactive' 
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update

let g:nvim_typescript#quiet_startup=1
let g:nvim_typescript#suggestions_enabled=0
let g:nvim_typescript#diagnosticsEnable=0
let g:nvim_typescript#javascript_support=1
" Plug 'davidsu/nvim-typescript', {'for': ['javascript', 'typescript', 'typescript.tsx'], 'do': './install.sh'}
Plug 'mhartington/nvim-typescript', {'for': ['javascript', 'typescript', 'typescript.tsx'], 'do': './install.sh'}
" ------------------------------------------------------------------------------------------------------------------------
" coc.nvim
" ------------------------------------------------------------------------------------------------------------------------
let coc_extension_npm = {'branch': 'master', 'do': 'yarn install --frozen-lockfile && yarn build --if-present'}                                                  " 
Plug 'neoclide/coc.nvim', coc_extension_npm
Plug 'neoclide/coc-git', coc_extension_npm                                                  " 
Plug 'weirongxu/coc-explorer', coc_extension_npm                                                  " 
Plug 'neoclide/coc-eslint', coc_extension_npm                                               
Plug 'neoclide/coc-tsserver', coc_extension_npm
Plug 'iamcco/coc-vimlsp', coc_extension_npm                                                  " 
Plug 'fannheyward/coc-marketplace', coc_extension_npm                                                  " 
Plug 'neoclide/coc-snippets', coc_extension_npm
" let g:coc_global_extensions = [
"       \'coc-git',
"       \'coc-explorer',
"       \'coc-eslint',
"       \'coc-tsserver',
"       \'coc-vimlsp',
"       \'coc-marketplace',
"       \'coc-snippets'
"       \]



Plug 'Konfekt/FastFold'                                             " fold zyntax is too heavy for vim, makes neocomplete very slow. this plugin solves it
if filereadable('/usr/local/opt/fzf')
  Plug '/usr/local/opt/fzf' | Plug 'davidsu/fzf.vim'                 " fuzzy file finder and so much more
else
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'davidsu/fzf.vim'                                              " fuzzy file finder and so much more
endif
Plug 'dahu/vim-fanfingtastic'                                       " improved f F t T commands
Plug 'davidsu/base16-vim'
Plug 'NLKNguyen/papercolor-theme'
Plug 'vim-airline/vim-airline'                                      " fancy statusline
Plug 'davidsu/vim-airline-themes'                                  " themes for vim-airline
" Plug 'mxw/vim-jsx', {'for': 'javascript'}
" Plug 'maxmellon/vim-jsx-pretty', {'for': 'javascript'}
Plug 'tpope/vim-commentary'                                         " comment stuff out
Plug 'davidsu/vim-unimpaired'                                      " mappings which are simply short normal mode aliases for commonly used ex commands
Plug 'tpope/vim-surround'                                           " mappings to easily delete, change and add such surroundings in pairs, such as quotes, parens, etc.
Plug 'tpope/vim-fugitive'                                           " amazing git wrapper for vim
Plug 'tpope/vim-rhubarb'                                            " for `:Gbrowse`
Plug 'tpope/vim-repeat'                                             " enables repeating other supported plugins with the . command
" Plug 'martinda/Jenkinsfile-vim-syntax'                              " Jenkins syntax
Plug 'davidsu/gv.vim'                                              " :GV browse commits like a pro
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
    " Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'jsx'] }
    Plug 'chemzqm/vim-jsx-improve',{ 'for': ['javascript', 'jsx'] } 
endif
" Plug 'maxmellon/vim-jsx-pretty'
Plug 'elzr/vim-json', { 'for': 'json' }                             " JSON support
Plug 'othree/es.next.syntax.vim', { 'for': 'javascript' }           " ES6 and beyond syntax
" Plug 'Quramy/tsuquyomi', { 'for': 'typescript', 'do': 'npm install' } " extended typescript support - works as a client for TSServer
" Plug 'leafgarland/typescript-vim', { 'for': 'typescript' } " typescript support
Plug 'cakebaker/scss-syntax.vim', { 'for': 'scss' }                 " sass scss syntax support
Plug 'wavded/vim-stylus', { 'for': ['stylus', 'markdown'] }         " markdown support
Plug 'ap/vim-css-color', { 'for': ['css','stylus','scss'] }         " set the background of hex color values to the color
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }                     " CSS3 syntax support
Plug 'dhruvasagar/vim-table-mode', {'for': 'markdown'}

highlight def link jsxCloseTag javascriptIdentifierName
highlight def link jsxCloseString javascriptIdentifierName
highlight def link jsxTag javascriptIdentifierName
hi link javascriptReserved javascriptVariable
hi link javascriptReservedCase javascriptVariable
call plug#end()
let g:sleuth_automatic = 1
