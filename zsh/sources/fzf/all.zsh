# fzf-all - Every fzf-based command here in one picker: what it does and its keys in the preview, Enter runs it
# Usage: fzf-all
# The table below is the registry: name, one line. The preview adds the command's own header comment
# and its fzf keys (--header / --prompt lines) read from the file that defines it.

FZF_ALL_COMMANDS=(
  "mru	Most recently used files (nvim's list); Enter opens the file in nvim at its last position"
  "jfzf	Jump to a frequently used directory (zoxide); Enter cd's there"
  "fa	Find a file under the current directory, bat preview; Enter opens it in nvim"
  "fag	ripgrep search; Enter loads the selected matches into nvim's quickfix (CTRL-l selects all)"
  "fbw	Bitwarden entries (rbw); Enter copies the password"
  "chromehistory	Chrome history; Enter opens the URL(s) in Chrome"
  "chromebookmarks	Chrome bookmarks; Enter opens the URL(s) in Chrome"
  "bravehistory	Brave history; Enter opens the URL(s) in Brave"
  "bravebookmarks	Brave bookmarks; Enter opens the URL(s) in Brave"
  "bot-awake	Live Claude agents with a colored live-screen preview; Enter focuses the agent's iTerm tab"
  "bot-available	Awake + asleep agents; Enter wakes an asleep one (teamup-wake) and focuses its tab"
  "terminal-tabs	Every iTerm tab with a live-screen preview; Enter focuses, CTRL-x closes the tab"
  "box attach	A Claude session on the Coder box; Enter attaches it in this iTerm tab"
)

fzf_all_entry() {
  local entry
  for entry in "${FZF_ALL_COMMANDS[@]}"; do
    [[ "$entry" == "$1"$'\t'* ]] && { print -r -- "${entry#*	}"; return; }
  done
}

fzf_all_defining_file() { # name — the function or alias that defines it; an alias or a bare name resolves to its bin/ script
  local name="${1%% *}" file target
  file="$(rg -l --no-config -e "^(function )?${name}\(\)" "$HOME/.dotfiles/zsh/sources" 2>/dev/null | head -1)"
  [[ -n "$file" ]] && { print -r -- "$file"; return; }
  target="$(rg --no-config -o "alias ${name}='[^ ']*" "$HOME/.dotfiles/zsh/sources" 2>/dev/null | head -1 | sed "s/.*='//")"
  [[ -x "$HOME/.dotfiles/bin/${target:-$name}" ]] && print -r -- "$HOME/.dotfiles/bin/${target:-$name}"
}

fzf_all_describe() {
  local name="$1" file
  print -P "%B${name}%b"
  fzf_all_entry "$name"
  file="$(fzf_all_defining_file "$name")"
  [[ -n "$file" ]] || return 0
  print -- "\ndefined in ${file/#$HOME/~}"
  print -- "\nkeys:"
  rg --no-config -o -e "--header[= ]+'[^']*'" -e "--prompt[= ]+'[^']*'" -e "# Usage:.*" "$file" | sed "s/^--//; s/[= ]\+'/ '/; s/  */ /g" | sort -u
}

function fzf-all() {
  local picked
  picked="$(printf '%s\n' "${FZF_ALL_COMMANDS[@]}" |
    fzf --delimiter '\t' --with-nth 1,2 --accept-nth 1 \
        --prompt 'fzf-all> ' \
        --header 'Enter: run the command | CTRL-/: toggle preview' \
        --preview 'zsh -ic "source ~/.dotfiles/zsh/sources/fzf/all.zsh; fzf_all_describe {1}" 2>/dev/null' \
        --preview-window 'up:50%:wrap')" || return
  [[ -n "$picked" ]] && eval "$picked"
}
