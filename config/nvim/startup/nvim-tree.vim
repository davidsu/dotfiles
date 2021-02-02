" nmap 1n :lua require('nvim-tree').buf_enter()<cr>:NvimTreeRefresh<cr>:NvimTreeFindFile<cr>
" nmap 1n :lua require('lib.lib').change_dir(vim.fn.getcwd())<cr>:NvimTreeRefresh<cr>:NvimTreeFindFile<cr>
nmap <c-n> :lua require('lib.lib').change_dir(vim.fn.getcwd())<cr>:NvimTreeRefresh<cr>:NvimTreeFindFile<cr>
" nmap 1n :lua require('lib.lib').change_dir(vim.fn.getcwd())<cr>:NvimTreeRefresh<cr>:NvimTreeFindFile<cr>
nmap <space>nt :NvimTreeToggle<cr>

function s:nvimTreeUpDir()
lua<<EOF
    local lib = require('lib.lib')
    local cwd = lib.Tree.cwd
    local current_node_path = lib.get_node_at_cursor().absolute_path
    local newcwd = vim.fn.fnamemodify(cwd, ':h')
    lib.change_dir(newcwd)
    lib.set_index_and_redraw(current_node_path)
EOF
    " let cwd = luaeval("require('lib.lib').Tree.cwd")
    " " let newcwd = substitute(cwd, '\(.*\)/.*', '\1', '')
    " let newcwd = fnamemodify(cwd, ':h')
    " execute "lua require('lib.lib').change_dir('".newcwd."')"
    " execute "lua require('lib.lib').set_index_and_redraw('"..".')"
endfunction

augroup nvim-tree-config
    autocmd!
    autocmd FileType NvimTree nnoremap <buffer>q :q<cr>
    autocmd FileType NvimTree nnoremap <buffer>- :call <SID>nvimTreeUpDir()<cr>
augroup END
