command! Rename call CocActionAsync('rename')
command! FixLint CocCommand eslint.executeAutofix

"refactor visual selection
xmap <space>rf <Plug>(coc-codeaction-selected)
nmap <space>lo :CocDiagnostics<cr>

inoremap <silent><expr> <TAB>
  \ pumvisible() ? coc#_select_confirm() :
  \ coc#expandableOrJumpable() ?
  \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  let result = !col || getline('.')[col - 1]  =~# '\s'
  echom 'checkbackspace'
  echom col
  echom result
  return result
endfunction

let g:coc_snippet_next = '<tab>'
nmap <space>cf <Plug>(coc-fix-current)

" function! s:disableDiagnosticsForTests()
"     if expand('%:p') =~ '/test'
"         let b:coc_diagnostic_disable = 1 
"     endif
" endfunction
" augroup davidsu-coc
"   au!
"   autocmd BufEnter javascript,typescript call <SID>disableDiagnosticsForTests()
" augroup END
" hack to stop coc annoying underlines, wouldn't work without defering
" lua vim.defer_fn(function() vim.api.nvim_command('hi CocUnderline cterm=NONE gui=NONE') end, 100)
" " lua vim.defer_fn(function() vim.api.nvim_command('hi clear SpellBad') end, 100)
" lua vim.defer_fn(function() vim.api.nvim_command('hi CocErrorVirtualText guifg=#69302a') end, 500)
" lua vim.defer_fn(function() vim.api.nvim_command('hi CocErrorSign guifg=#ba2614 guibg=#32302F') end, 500)
