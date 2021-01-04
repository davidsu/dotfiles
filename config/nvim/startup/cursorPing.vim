function! CursorPing(...)
    let _cursorline = &cursorline
    let _cursorcolumn = &cursorcolumn
    set cursorline 
    if !a:0
    set cursorcolumn
    endif
    redraw
    sleep 200m
    let &cursorline = _cursorline
    let &cursorcolumn = _cursorcolumn
endfunction
