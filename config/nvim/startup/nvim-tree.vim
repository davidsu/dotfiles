nmap 1n :lua require('nvim-tree').buf_enter()<cr>:NvimTreeFindFile<cr>

augroup nvim-tree-config
    autocmd!
    autocmd FileType NvimTree nnoremap <buffer>q :q<cr>
augroup END
