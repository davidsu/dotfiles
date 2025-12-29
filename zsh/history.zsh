#!/bin/zsh
# History Configuration
# Based on dotfilesold/history with modern best practices

# History file location and size
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Core history options
setopt APPEND_HISTORY           # append to history file (don't overwrite)
setopt SHARE_HISTORY           # share history across all sessions (real-time)
setopt HIST_VERIFY             # don't execute immediately upon history expansion

# Duplicate handling
setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS        # don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS    # delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS       # don't display duplicates when searching history
setopt HIST_SAVE_NO_DUPS       # don't write duplicate entries to history file

# Other useful options
setopt HIST_IGNORE_SPACE       # don't record entries starting with a space
