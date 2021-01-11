local hasPacker = require 'utils'.hasPacker
if not hasPacker() then
  os.execute('git clone https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/opt/packer.nvim')
end
vim.api.nvim_command('packadd packer.nvim')


function cocTable(cocPlugin)
  return {
    cocPlugin,
    branch = 'master',
    run = 'yarn install --frozen-lockfile && yarn build --if-present'
  }
end
return require('packer').startup(function()
  use(cocTable('neoclide/coc.nvim'))
  use(cocTable('neoclide/coc-git'))
  use(cocTable('weirongxu/coc-explorer'))
  use(cocTable('neoclide/coc-eslint'))
  use(cocTable('neoclide/coc-tsserver'))
  use(cocTable('iamcco/coc-vimlsp'))
  use(cocTable('fannheyward/coc-marketplace'))
  use(cocTable('neoclide/coc-snippets'))
  -- let g:coc_global_extensions = [
  --       \'coc-git',
  --       \'coc-explorer',
  --       \'coc-eslint',
  --       \'coc-tsserver',
  --       \'coc-vimlsp',
  --       \'coc-marketplace',
  --       \'coc-snippets'
  --       \]

  if vim.loop.fs_stat('/usr/local/opt/fzf') then
    use '/usr/local/opt/fzf' 
    use 'davidsu/fzf.vim'                 
  else
    use { 'junegunn/fzf', run = ':call fzf#install()' }
    use 'davidsu/fzf.vim'
  end

  use 'ssh://git@git.walkmedev.com:7999/~david.susskind/walkme-vim-gbrowse.git'
  use 'davidsu/comfortable-motion.vim'                               
  use( os.getenv('DOTFILES') .. '/js/vim-js' )
  use { 'tweekmonster/startuptime.vim', cmd = 'StartupTime' }  
  use 'tommcdo/vim-exchange'                                         -- exchange text with cx
  use 'davidsu/vim-visual-star-search'                               -- extends */# to do what you would expect in visual mode
  -- use 'davidsu/vim-bufkill'                                          -- wipe buffer without closing it's window
  use 'tpope/vim-scriptease'                                         -- utilities for vim script authoring. Installed to use ':PP'=pretty print dictionary
  use 'inkarkat/vim-ingo-library'                                    -- dependency of vim-mark
  use 'idbrii/vim-mark'                                              -- highlighting of interesting words
  use { 'schickling/vim-bufonly', cmd = 'BufOnly' }                  -- delete all buffers but current
  use { 'davidsu/vim-plugin-AnsiEsc', cmd = 'AnsiEsc' }              -- type :AnsiEsc to get colors as terminal
  use 'blueyed/vim-diminactive' 
  use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }        -- We recommend updating the parsers on update
  use 'nvim-treesitter/playground'
  use 'dahu/vim-fanfingtastic'                                       -- improved f F t T commands
  -- use 'davidsu/base16-vim'
  use 'davidsu/nvcode-color-schemes.vim'

  use { 'glepnir/galaxyline.nvim', branch = 'main' }
  use 'tpope/vim-commentary'                                         -- comment stuff out
  use 'davidsu/vim-unimpaired'                                       -- mappings which are simply short normal mode aliases for commonly used ex commands
  use 'tpope/vim-surround'                                           -- mappings to easily delete, change and add such surroundings in pairs, such as quotes, parens, etc.
  use 'tpope/vim-fugitive'                                           -- amazing git wrapper for vim
  use 'tpope/vim-rhubarb'                                            -- for `:Gbrowse`
  use 'tpope/vim-repeat'                                             -- enables repeating other supported plugins with the . command
  use { 'davidsu/gv.vim', cmd = 'GV' }                               -- :GV browse commits like a pro
  use 'tpope/vim-sleuth'                                             -- detect indent style (tabs vs. spaces)
  use 'sickill/vim-pasta'                                            -- fix indentation when pasting
  use { 'junegunn/limelight.vim', cmd = 'Limelight' }                -- focus tool. Good for presentating with vim
  use { 'mattn/emmet-vim', ft = 'html' }                             -- emmet support for vim - easily create markdup wth CSS-like syntax
  use 'alvan/vim-closetag'
  use { 'othree/html5.vim', ft = 'html' }                            -- html5 support
  use { 'cakebaker/scss-syntax.vim', ft = 'scss' }                   -- sass scss syntax support
  use 'norcalli/nvim-colorizer.lua'
  use { 'hail2u/vim-css3-syntax', ft = 'css' }                       -- CSS3 syntax support
  use { 'wavded/vim-stylus', ft = {'stylus', 'markdown'} }           -- markdown support
  use { 'dhruvasagar/vim-table-mode', ft = 'markdown'}
  use {'junegunn/vim-xmark' , run = 'make', ft = { 'markdown' }}     -- ❌ Markdown preview on OS X
  use {'plasticboy/vim-markdown', ft = 'markdown'}                   -- markdown
  use {'godlygeek/tabular', ft = 'markdown'}                         -- related to vim-markdown
end)

