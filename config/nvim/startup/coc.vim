function! RunPrettier()
  write
  let file = expand('%:p')
  let root = utils#get_project_root(file)
  call utils#run_shell_command('cd '.root.'; yarn run prettier -w '.expand('%:p'), 0)
  edit
endfunction
command! Rename call CocActionAsync('rename')
command! FixLint CocCommand eslint.executeAutofix
command! -nargs=0 Prettier :CocCommand prettier.forceFormatDocument
command! -nargs=* -range CocAction :call coc#rpc#notify('codeActionRange', [<line1>, <line2>, <f-args>])
command! -nargs=* -range CocFix    :call coc#rpc#notify('codeActionRange', [<line1>, <line2>, 'quickfix'])

function! FocusInExplorer()
  for window in getwininfo()
    if getbufvar(window.bufnr, '&ft') == 'coc-explorer'
      execute window.winnr . 'wincmd q'
    endif
  endfor
  execute 'CocCommand explorer --reveal '.expand('%:p')
endfunction
"refactor visual selection
nmap 1n :<c-u>CocCommand explorer<cr>
nmap <space>nf :call FocusInExplorer()<cr>

nmap <space>cd :call coc#float#close_all()<cr>:call CocActionAsync('jumpDefinition')<cr>
xmap <space>rf <Plug>(coc-codeaction-selected)
nmap <space>lo :CocDiagnostics<cr>
nmap <C-c> <Plug>(coc-float-hide)
nmap <space>cf <Plug>(coc-fix-current)
imap <C-e> <Esc>:call coc#float#close_all()<cr>:call feedkeys('a')<cr>
function! Check_back_space() abort
  let col = col('.') - 1
  let result = !col || getline('.')[col - 1]  =~# '\s'
  echom 'checkbackspace'
  echom col
  echom result
  return result
endfunction
imap <silent><expr> <TAB>
  \ coc#pum#visible() ? "\<C-Y>" :
  \ coc#expandableOrJumpable() ?
  \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
  \ Check_back_space() ? "\<TAB>" :
  \ coc#refresh()
" inoremap <silent><expr> <TAB>
"   \ pumvisible() ? coc#_select_confirm() :
"   \ coc#expandableOrJumpable() ?
"   \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
"   \ Check_back_space() ? "\<TAB>" :
"   \ coc#refresh()


let g:coc_global_extensions = [
      \'coc-git',
      \'coc-explorer',
      \'coc-eslint',
      \'coc-tsserver',
      \'coc-vimlsp',
      \'coc-marketplace',
      \'coc-snippets',
      \'coc-yaml',
      \'coc-swagger'
      \]
let g:coc_snippet_next = '<Tab>'
let g:coc_snippet_prev = '<S-Tab>'
