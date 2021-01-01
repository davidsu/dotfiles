"-----------------------------------------------------------------------------}}}
"FUNCTIONS                                                                    {{{ 
"--------------------------------------------------------------------------------
function! ExecMapping(line)
    let l:mapping = matchstr(a:line, '^\S*')
    call feedkeys(substitute(l:mapping, '<[^ >]\+>', '\=eval("\"\\".submatch(0)."\"")', 'g'))
endfunction

function! Base16_ColoReferenceDONTRUNME()
	"great theme
	colo base16-tomorrow-night
	colo base16-monokai
	colo base16-railscasts
	colo base16-ondark
endfunction
"-----------------------------------------------------------------------------}}}
"AUTOCOMMANDS                                                                 {{{
"--------------------------------------------------------------------------------
"-----------------------------------------------------------------------------}}}
