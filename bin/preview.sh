#!/usr/bin/env bash
# Preview script for fzf
# Usage: preview.sh file[:line][:col]
# Based on dotfilesold/bin/preview.sh but using bat

if [[ -z "$1" ]]; then
    echo "usage: $0 FILENAME[:LINENO][:IGNORED]"
    exit 1
fi

# Parse file:line:col format
IFS=':' read -r -a INPUT <<< "$1"
FILE=${INPUT[0]}
CENTER=${INPUT[1]}

# Handle Windows paths (just in case)
if [[ $1 =~ ^[A-Z]:\\ ]]; then
    FILE=$FILE:${INPUT[1]}
    CENTER=${INPUT[2]}
fi

# Validate line number is numeric
if [[ -n "$CENTER" && ! "$CENTER" =~ ^[0-9] ]]; then
    exit 1
fi
# Strip any non-numeric characters from line number
CENTER=${CENTER/[^0-9]*/}

# Expand ~ to $HOME
FILE="${FILE/#\~\//$HOME/}"

if [[ ! -r "$FILE" ]]; then
    echo "File not found: ${FILE}"
    exit 1
fi

# Check if file is binary
FILE_LENGTH=${#FILE}
MIME=$(file --dereference --mime "$FILE")
if [[ "${MIME:FILE_LENGTH}" =~ binary ]]; then
    echo "$MIME"
    exit 0
fi

# Default to line 0 if not specified
if [[ -z "$CENTER" ]]; then
    CENTER=0
fi

# Check for bat/batcat
if command -v batcat > /dev/null; then
    BATNAME="batcat"
elif command -v bat > /dev/null; then
    BATNAME="bat"
fi

# Use bat if available
if [[ -n "${BATNAME}" ]]; then
    ${BATNAME} --style="${BAT_STYLE:-numbers}" \
        --color=always \
        --pager=never \
        --highlight-line=$CENTER \
        "$FILE"
    exit $?
fi

# Fallback to cat if bat not available
cat "$FILE"
