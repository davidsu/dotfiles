call plug#begin('~/.config/nvim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'idbrii/vim-mark'                                              " highlighting of interesting words
Plug '/usr/local/opt/fzf' | Plug 'sudavid4/fzf.vim'                 " fuzzy file finder and so much more
Plug 'sudavid4/base16-vim'
Plug 'vim-airline/vim-airline'                                      " fancy statusline
Plug 'sudavid4/vim-airline-themes'                                  " themes for vim-airline
Plug 'neoclide/coc.nvim'
Plug 'henrik/vim-indexed-search'                                    " Match 123 of 456 /search term/ in Vim searches
Plug 'sudavid4/vim-unimpaired'                                      " mappings which are simply short normal mode aliases for commonly used ex commands
Plug 'yuttie/comfortable-motion.vim'                               " Brings physics-based smooth scrolling to the Vim world!
call plug#end()
source $HOME/.config/nvim/startup/hzf.vim
source $HOME/.config/nvim/startup/leader_mappings.vim
source $HOME/.config/nvim/startup/abbrev.vim
source $HOME/.config/nvim/startup/windowStuff.vim
source $HOME/.config/nvim/startup/comfortable_motion.vim
nmap <space>bl :Lines<cr>
let base16colorspace=256  " Access colors present in 256 colorspace"
set termguicolors
colorscheme base16-chalk
set ignorecase            " case insensitive searching
set smartcase             " case-sensitive if expresson contains a capital letter

let mapleader = ','
let g:mapleader = ','
nmap 1n :execute 'e '.getcwd()<cr>
nmap - :execute 'e '.getcwd()<cr>
" unmap /
