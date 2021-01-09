command! Rename call CocActionAsync('rename')
command! FixLint CocCommand eslint.executeAutofix

function! FocusInExplorer()
  let windows = filter(getwininfo(), 'v:val.tabnr == '.gettabinfo()[0].tabnr)
  for window in getwininfo()
    if getbufvar(window.bufnr, '&ft') == 'coc-explorer'
      execute window.winnr . 'wincmd q'
    endif
  endfor
  execute 'CocCommand explorer --reveal '.expand('%:p')
endfunction

nmap <space>nf :call FocusInExplorer()<cr>
"refactor visual selection
xmap <space>rf <Plug>(coc-codeaction-selected)
nmap <space>lo :CocDiagnostics<cr>
nmap <C-c> <Plug>(coc-float-hide)
nmap <space>cf <Plug>(coc-fix-current)

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
