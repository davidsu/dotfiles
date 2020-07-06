# c - browse chrome history
# copied from https://junegunn.kr/2015/04/browsing-chrome-history-with-fzf/
chromehistory() {
  local cols sep 
  cols=$(( COLUMNS / 3 ))
  sep='{::}'


  #whenever you need to find what is the proper history file use this piece of code from ...Support/Google/
  #taken from https://stackoverflow.com/questions/4561895/how-to-recursively-find-the-latest-modified-file-in-a-directory
  #find . -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" "
  historyfile=~/Library/Application\ Support/Google/Chrome/Profile\ 5/History
  if [[ ! -f $historyfile ]]; then
      historyfile=~/Library/Application\ Support/Google/Chrome/Default/History
      if [[ ! -f $historyfile ]]; then
          echo 'cannot find history file'
          return
      fi
  fi
  # /Default/History
  cp -f $historyfile /tmp/h

  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi \
      --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1\
'$(tput setaf 10)'#g'\' \
        --preview-window 'up:35%:wrap' \
        --header 'CTRL-o - open without abort :: CTRL-s - toggle sort :: CTRL-g - toggle preview window' \
        --prompt 'Chrome History>' \
        --bind 'ctrl-g:toggle-preview,ctrl-s:toggle-sort,ctrl-o:execute:open {-1}' | perl -pe 's|.*?(https*://.*?)|\1|' | xargs open
}

alias -g F=' | fzf --ansi --preview '\''$DOTFILES/bin/preview.rb {}'\'' --preview-window '\''top:50%'\'' --bind '\''ctrl-s:toggle-sort,ctrl-g:toggle-preview,ctrl-o:execute:($DOTFILES/fzf/fhelp.sh {})'\'
alias fch='chromehistory'  

fstash() {
  git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
  fzf --ansi --no-sort \
      --header 'CTRL-o - git diff without abort :: CTRL-s - toggle sort :: CTRL-g - toggle preview window' \
      --preview-window 'up:55%:wrap' \
      --preview 'git stash show {1} > /tmp/tmp; echo "" >> /tmp/tmp; git stash show -p --color {1} >> /tmp/tmp; cat /tmp/tmp' \
      --bind 'ctrl-g:toggle-preview,ctrl-s:toggle-sort,ctrl-o:execute:git stash show -p {1}' | perl -pe 's#(.*?) .*#\1#' | pbcopy
  rm /tmp/tmp
}
# fbr - checkout git branch (including remote branches)
fbr() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
function fag(){
    fzfretval=$(rgf $@ | fzf -m  --ansi --preview '$DOTFILES/bin/preview.rb {}' \
        --preview-window 'top:50%' \
        --bind 'ctrl-l:select-all,ctrl-s:toggle-sort,ctrl-g:toggle-preview,ctrl-o:execute:($DOTFILES/fzf/fhelp.sh {}) > /dev/tty' \
        --header 'CTRL-l - select-all :: CTRL-o - open without abort(LESS) :: CTRL-s - toggle sort :: CTRL-g - toggle preview window')
    #note the `< <` here has the same effect as <<. not obvious what could be the difference. see `man zshexpn` +228 for more. here the `<<` fucks up syntax highlight
    #for more on `<<<` see `here string` on `man bash`
    IFS=: read filename linenum ignorerest< <(sed -E 's/([^:]*:[[:digit:]]+)/\1:/' <<< $fzfretval)
    if [[ -f $filename ]]; then
        echo '' > /tmp/mruretval
        echo $fzfretval >> /tmp/mruretval
        if [[ $(wc -l < /tmp/mruretval) -ge 1 ]]; then
          vim -c 'cd '`pwd` -c 'AutoCDCancel' -c 'call fzf#vim#MruHandler()'
        else
          vim -c 'cd '`pwd` -c 'call fzf#vim#MruHandler()'
        fi
    fi
}
alias rgf='rg --line-number --column --color "ansi" '
function fa(){
    filename=$(find . -type f | fzf --exact --preview '$DOTFILES/bin/preview.rb {}' \
                --preview-window 'top:50%' \
    --header 'CTRL-o - open without abort(LESS) :: CTRL-s - toggle sort :: CTRL-g - toggle preview window' \
    --bind 'ctrl-s:toggle-sort,ctrl-g:toggle-preview,ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {}:0 > /dev/tty')
    if [[ -f $filename ]]; then
        #man zshzle for what's happenning here
        # LBUFFER="${LBUFFER}${filename}"
        # zle redisplay
        vim $filename
    fi
}
function fman(){
    if [[ $# -eq 0 ]]; then
        echo 'need a search argument for this'
        return
    fi
    export FMAN_SEARCH_PATTERN=$(sed 's/\\b//g' <<< ${@: -1})
    fzfretval=$(findmanpage $@ | fzf --ansi --preview '$DOTFILES/bin/preview.rb {}' --preview-window 'top:50%' --bind 'ctrl-g:toggle-preview,ctrl-s:toggle-sort,ctrl-o:execute:($DOTFILES/bin/fmaopen {}) > /dev/tty')
    if [[ -n $fzfretval ]]; then
        manpage=$(sed -E 's#.*/(.*)\..*#\1#' <<< $( sed -E 's#([^[:space:]]*):[[:digit:]]+:.*#\1#' <<< $fzfretval))
        man -P "nvim -c 'set ft=man' - +/$FMAN_SEARCH_PATTERN" $manpage 
        # man -P "less -i -j12 -p $searchpattern" $manpage 
    fi
}
# fshow - git commit browser
# copied from https://junegunn.kr/2015/03/browsing-git-commits-with-fzf/
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

alias chromebookmarks='$DOTFILES/fzf/chromebookmarks.rb'
function jfzf(){
  dir=`fasd_cd -ds | egrep '^\S+\s+/' | tac | fzf --no-sort --bind 'ctrl-s:toggle-sort'`
  if [[ -n dir ]]; then
    dir=$(echo $dir | sed -E 's#[^/]*(/.*$)#''\1''#')
    [[ -d $dir ]] && cd $dir
  fi
}
alias jf='jfzf'
alias fj='jfzf'
# /Users/davidsu/Library/Application Support/Google/Chrome/Profile 1
fzf-chth(){
  local selected
  if selected=$(find $DOTFILES/base16-shell/scripts | fzf ); then
    source $selected
    local _theme=`echo $selected | tr '/' '\n' | egrep 'base.*sh$'`
    THEME=${_theme:0:-3}
    zle redisplay
    # THEME=selected
  fi
}
zle     -N    fa
bindkey '^Y' fa
alias fchth='fzf-chth'
alias fcd=fzf-cd-widget
# fzf-locate-widget() {
#   local selected
#   if selected=$(find $DOTFILES/base16-shell/scripts | fzf ); then
#     LBUFFER=$selected
#   fi
#   zle redisplay
# }
# zle     -N    fzf-locate-widget
# bindkey '^N' fzf-locate-widget
