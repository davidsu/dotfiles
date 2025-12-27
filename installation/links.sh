#!/usr/bin/env bash

# Symlinking Logic for Dotfiles
# Handles linking the config directory and individual .symlink files

# Source logging if not already available
if [[ -z "$(declare -F log_info)" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Helper to safely create a symlink
# $1: source file (absolute path)
# $2: target path (absolute path)
safe_link() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" ]]; then
        local current_link
        current_link=$(readlink "$dest")
        if [[ "$current_link" == "$src" ]]; then
            log_success "Link already exists: $dest -> $src"
            return 0
        else
            log_warn "Existing link $dest points to $current_link. Backing up..."
            if ! mv "$dest" "${dest}.bak"; then
                log_error "Failed to back up existing link: $dest"
                return 1
            fi
        fi
    elif [[ -e "$dest" ]]; then
        log_warn "Existing file $dest found. Backing up to ${dest}.bak"
        if ! mv "$dest" "${dest}.bak"; then
            log_error "Failed to back up existing file: $dest"
            return 1
        fi
    fi

    # Create parent directory if it doesn't exist
    if ! mkdir -p "$(dirname "$dest")"; then
        log_error "Failed to create directory: $(dirname "$dest")"
        return 1
    fi

    if ln -s "$src" "$dest"; then
        log_success "Created link: $dest -> $src"
    else
        log_error "Failed to create link: $dest -> $src"
        return 1
    fi
}

# Function to find and link all .home.symlink and .home.zsh files in the repo
link_home_files() {
    local dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local failed=0
    log_info "Finding .home.symlink and .home.zsh files in $dotfiles_root..."

    # Use a temporary file to store the list of links to avoid subshell issues with 'while'
    local symlink_list
    symlink_list=$(mktemp)
    
    # Find both .home.symlink and .home.zsh files
    find "$dotfiles_root" \( -name "*.home.symlink" -o -name "*.home.zsh" \) -not -path "*/.git/*" > "$symlink_list"

    while read -r src; do
        [[ -z "$src" ]] && continue
        local filename
        filename=$(basename "$src")
        local target_name
        
        if [[ "$filename" == *.home.symlink ]]; then
            target_name=".${filename%.home.symlink}"
        elif [[ "$filename" == *.home.zsh ]]; then
            target_name=".${filename%.home.zsh}"
        fi
        
        local dest="${HOME}/${target_name}"

        if ! safe_link "$src" "$dest"; then
            failed=$((failed + 1))
        fi
    done < "$symlink_list"
    rm "$symlink_list"

    return $failed
}

# Main symlinking entry point
setup_symlinks() {
    log_info "Starting symlinking process..."
    
    if ! link_home_files; then
        log_error "Symlinking process completed with errors."
        return 1
    else
        log_success "Symlinking process completed successfully."
        return 0
    fi
}
