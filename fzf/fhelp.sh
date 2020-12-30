#!/bin/zsh
sanitized=$(sed -E 's/^[[:space:]]*[[:digit:]]+[[:space:]]+(.*)/\1/' <<< $1)
linenum=$(echo $sanitized | sed -E "s/[^:]*:([^:]*).*/\1/")
filename=$(echo $sanitized | sed -E "s/([^:]*):.*/\1/")
if [[ $linenum -gt 30 ]]; then
	gotolinenum=$(expr $linenum - 20) 
elif [[ $linenum -gt 25 ]]; then
	gotolinenum=$(expr $linenum - 10)
else
	gotolinenum=0
fi

# $DOTFILES/fzf/fhelp.rb ${filename}:${linenum} | less -N +${gotolinenum}g
$DOTFILES/bin/preview.sh ${filename}:${linenum} | less -N +${gotolinenum}g

