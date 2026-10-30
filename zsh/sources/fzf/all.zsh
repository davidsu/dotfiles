# fzf-all - Every fzf-based command here in one picker: what it does and its keys in the preview, Enter runs it
# Usage: fzf-all (alias: fzf-land)
# The table below is the registry: name, global hotkey (blank if none), one line. The preview adds the command's header comment
# and its fzf keys (--header / --prompt lines) read from the file that defines it.

FZF_ALL_COMMANDS=(
  "mru	cmd+ctrl+t	Most recently used files (nvim's list); Enter opens the file in nvim at its last position"
  "jfzf		Jump to a frequently used directory (zoxide); Enter cd's there"
  "fa		Find a file under the current directory, bat preview; Enter opens it in nvim"
  "fag		ripgrep search: pick a directory (default ~/projects/apper), type the rg args, matches → nvim's quickfix"
  "fbw		Bitwarden entries (rbw); Enter copies the password"
  "chromehistory	cmd+ctrl+c	Chrome history; Enter opens the URL(s) in Chrome"
  "chromebookmarks	cmd+ctrl+b	Chrome bookmarks; Enter opens the URL(s) in Chrome"
  "bravehistory		Brave history; Enter opens the URL(s) in Brave"
  "bravebookmarks		Brave bookmarks; Enter opens the URL(s) in Brave"
  "bot-awake	cmd+ctrl+a	Live Claude agents with a colored live-screen preview; Enter focuses the agent's iTerm tab"
  "bot-available		Awake + asleep agents; Enter wakes an asleep one (teamup-wake) and focuses its tab"
  "terminal-tabs		iTerm tabs without an agent (shells, nvim…), live-screen preview; Enter focuses, CTRL-x closes the tab"
  "chrome-tabs		Every Chrome tab (title, URL); Enter goes to it, CTRL-x closes it"
  "fzf-slack		Slack's cmd+k in fzf: channels and DMs (cached), preview = latest messages; Enter opens it in Slack"
)

fzf_all_entry() { # name — "hotkey<TAB>description"
  local entry
  for entry in "${FZF_ALL_COMMANDS[@]}"; do
    [[ "$entry" == "$1"$'\t'* ]] && { print -r -- "${entry#*	}"; return; }
  done
}

fzf_all_hotkey() { local entry; entry="$(fzf_all_entry "$1")"; print -r -- "${entry%%	*}"; }
fzf_all_description() { local entry; entry="$(fzf_all_entry "$1")"; print -r -- "${entry#*	}"; }

fzf_all_defining_file() { # name — the function or alias that defines it; an alias or a bare name resolves to its bin/ script
  local name="${1%% *}" file target
  file="$(rg -l --no-config -e "^(function )?${name}\(\)" "$HOME/.dotfiles/zsh/sources" 2>/dev/null | head -1)"
  [[ -n "$file" ]] && { print -r -- "$file"; return; }
  target="$(rg --no-config -o "alias ${name}='[^ ']*" "$HOME/.dotfiles/zsh/sources" 2>/dev/null | head -1 | sed "s/.*='//")"
  [[ -x "$HOME/.dotfiles/bin/${target:-$name}" ]] && print -r -- "$HOME/.dotfiles/bin/${target:-$name}"
}

fzf_all_describe() {
  local name="$1" file
  print -P "%B${name}%b${$(fzf_all_hotkey "$name"):+  (global: $(fzf_all_hotkey "$name"), floating window)}"
  fzf_all_description "$name"
  file="$(fzf_all_defining_file "$name")"
  [[ -n "$file" ]] || return 0
  print -- "\ndefined in ${file/#$HOME/~}"
  print -- "\nkeys:"
  rg --no-config -o -e "--header[= ]+'[^']*'" -e "--prompt[= ]+'[^']*'" -e "# Usage:.*" "$file" | sed "s/^--//; s/[= ]\+'/ '/; s/  */ /g" | sort -u
}

fzf_all_rows() { # name <TAB> aligned display line: name, hotkey, description
  local entry name rest
  for entry in "${FZF_ALL_COMMANDS[@]}"; do
    name="${entry%%	*}"; rest="${entry#*	}"
    printf '%s\t%-16s %-12s %s\n' "$name" "$name" "${rest%%	*}" "${rest#*	}"
  done
}

FZF_ALL_FAG_DEFAULT_DIR="$HOME/projects/apper"

fzf_all_pick_directory() { # ~/projects/apper first, then zoxide's list; Esc keeps the default
  { print -r -- "$FZF_ALL_FAG_DEFAULT_DIR"; zoxide query -l 2>/dev/null | grep -vx "$FZF_ALL_FAG_DEFAULT_DIR"; } |
    fzf --prompt 'fag in> ' --header "Enter: search there | ESC: ${FZF_ALL_FAG_DEFAULT_DIR/#$HOME/~}" --no-sort --preview 'ls -1 {}' --preview-window 'right:40%' ||
    print -r -- "$FZF_ALL_FAG_DEFAULT_DIR"
}

fzf_all_ask_rg_args() { # dir — the search term and any rg flags, typed into an fzf prompt; Esc aborts
  true | fzf --print-query --no-info --prompt "rg args in ${1/#$HOME/~}> " --header 'term and flags, e.g. useEffect -g "*.tsx" | Enter: search | ESC: abort' | head -1
}

fzf_all_run_fag() {
  local dir rg_args
  dir="$(fzf_all_pick_directory)"
  rg_args="$(fzf_all_ask_rg_args "$dir")"
  [[ -n "$rg_args" ]] || return
  ( cd "$dir" && fag ${(z)rg_args} )
}

fzf_all_run() {
  case "$1" in
    fag) fzf_all_run_fag ;;
    *) eval "$1" ;;
  esac
}

function fzf-all() {
  local picked
  picked="$(fzf_all_rows |
    fzf --delimiter '\t' --with-nth 2 --accept-nth 1 \
        --prompt 'fzf-all> ' \
        --header 'Enter: run the command | CTRL-/: toggle preview' \
        --preview 'zsh -c "source ~/.dotfiles/zsh/sources/fzf/all.zsh; fzf_all_describe {1}"' \
        --preview-window 'up:50%:wrap')" || return
  [[ -n "$picked" ]] && fzf_all_run "$picked"
}

alias fzf-land='fzf-all'
