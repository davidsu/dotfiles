command! Rename :call CocActionAsync('rename')<cr>
command! FixLint :CocCommand eslint.executeAutofix<cr>

"refactor visual selection
xmap <space>rf <Plug>(coc-codeaction-selected)
