set nocompatible          " not compatible with vi
" set maxmemtot=2000000     " give vim some memory - it get's stuck when working with very large files
set autoread              " detect when a file is changed
set autowriteall          " just :w implicitly, allways
set grepprg=ag\ --vimgrep\ $*
set grepformat=%f:%l:%c:%m
set backspace=indent,eol,start
set history=1000          " change history to 1000
set textwidth=1000        " don't automatic insert newlines on me!!!
set expandtab             " insert tabs rather than spaces for <Tab>
set smarttab              " tab respects 'tabstop', 'shiftwidth', and 'softtabstop'
set tabstop=4             " the visible width of tabs
set softtabstop=4         " edit as if the tabs are 4 characters wide
set shiftwidth=4          " number of spaces to use for indent and unindent
set shiftround            " round indent to a multiple of 'shiftwidth'
set completeopt+=longest
set ttyfast
set diffopt+=vertical
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set noswapfile
set laststatus=2          " show the satus line all the time
set sessionoptions-=folds
set foldmethod=syntax     " fold based on indent
set foldnestmax=10        " deepest fold is 10 levels
set nofoldenable          " don't fold by default
set foldlevel=1
set so=7                  " set 7 lines to the cursors - when moving vertical
set wildmenu              " enhanced command line completion
set hidden                " current buffer can be put into background
set showcmd               " show incomplete commands
set noshowmode            " don't show which mode disabled for PowerLine
" set wildmode=list:longest " complete files like a shell
" use <c-space> for shell-like completions!?
set wildmode=full " complete files like a shell
set scrolloff=3           " lines of text around cursor
set shell=$SHELL
set cmdheight=1           " command bar height
set title                 " set terminal title
set ignorecase            " case insensitive searching
set smartcase             " case-sensitive if expresson contains a capital letter
" set hlsearch
" set incsearch             " set incremental search, like modern browsers
set lazyredraw            " don't redraw while executing macros
set magic                 " Set magic on, for regex
set noerrorbells
set visualbell
set shada=!,'500,<50,s10,h,%
set t_vb=
set tm=500
set t_Co=256              " Explicitly tell vim that the terminal supports 256 colors"
set background=dark
set number                " show line numbers
set nowrap                " turn on line wrapping
set wrapmargin=8          " wrap lines when coming within n characters from side
set linebreak             " set soft wrapping
set showbreak=…           " show ellipsis at breaking
set autoindent            " automatically set indent of new line
set smartindent
set pastetoggle=<F6>
set nolist
set listchars=tab:→\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
set showbreak=↪
set nospell
