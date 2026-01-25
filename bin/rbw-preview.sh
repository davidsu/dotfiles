#!/bin/bash
# Preview script for rbw entries with numbered fields

entry="$1"
if [[ -z "$entry" ]]; then
    echo "No entry selected"
    exit 0
fi

# Get raw JSON
json=$(rbw get "$entry" --raw 2>/dev/null)
if [[ -z "$json" ]]; then
    echo "Failed to fetch entry"
    exit 0
fi

# Colors
CYAN='\033[1;36m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[36m'
MAGENTA='\033[35m'
GRAY='\033[90m'
RESET='\033[0m'

# Column width for alignment (plain text, no ANSI codes)
COL_WIDTH=60

# Capture all content in a variable
content=""

# Helper function to add line to content
add_line() {
    content+="$1"$'\n'
}

# Helper function to print aligned line
print_field() {
    local color="$1"
    local label="$2"
    local value="$3"
    local keybind="$4"

    local text="$label $value"
    local padding=$((COL_WIDTH - ${#text}))
    local spaces=$(printf '%*s' "$padding" '')

    add_line "${color}${label}${RESET} ${value}${spaces}${GREEN}${keybind}${RESET}"
}

# Map field positions to keys
# Avoid terminal defaults: a, c, d, e, k, l, r, t, u, w, y, z
# Avoid fzf: o (open), p/n (navigation), s (sort)
# Safe to use: Ctrl+b,f,g,h,i,j,m,q,v,x + Shift+b,f,g,h,i,j,m,q,v,x (20 keys total)
keys=(b f g h i j m q v x B F G H I J M Q V X)
field_num=0

# Header
add_line "${CYAN}━━━ $entry ━━━${RESET}"
add_line ""

# Detect entry type (identity vs card vs login)
first_name=$(echo "$json" | jq -r '.data.first_name // empty')
cardholder_name=$(echo "$json" | jq -r '.data.cardholder_name // empty')

if [[ -n "$first_name" ]]; then
    # IDENTITY ENTRY

    # Full name
    last_name=$(echo "$json" | jq -r '.data.last_name // empty')
    full_name="$first_name${last_name:+ $last_name}"
    key="${keys[$field_num]}"
    print_field "$GREEN" "Name:" "$full_name" "[Ctrl+$key]"
    ((field_num++))

    # Email
    email=$(echo "$json" | jq -r '.data.email // empty')
    if [[ -n "$email" ]]; then
        key="${keys[$field_num]}"
        print_field "$BLUE" "Email:" "$email" "[Ctrl+$key]"
        ((field_num++))
    fi

    # Phone
    phone=$(echo "$json" | jq -r '.data.phone // empty')
    if [[ -n "$phone" ]]; then
        key="${keys[$field_num]}"
        print_field "$MAGENTA" "Phone:" "$phone" "[Ctrl+$key]"
        ((field_num++))
    fi

    # Address
    address1=$(echo "$json" | jq -r '.data.address1 // empty')
    city=$(echo "$json" | jq -r '.data.city // empty')
    if [[ -n "$address1" || -n "$city" ]]; then
        state=$(echo "$json" | jq -r '.data.state // empty')
        postal=$(echo "$json" | jq -r '.data.postal_code // empty')
        country=$(echo "$json" | jq -r '.data.country // empty')
        addr_parts=()
        [[ -n "$address1" ]] && addr_parts+=("$address1")
        [[ -n "$city" ]] && addr_parts+=("$city")
        [[ -n "$state" ]] && addr_parts+=("$state")
        [[ -n "$postal" ]] && addr_parts+=("$postal")
        [[ -n "$country" ]] && addr_parts+=("$country")
        address=$(IFS=", "; echo "${addr_parts[*]}")
        key="${keys[$field_num]}"
        print_field "$CYAN" "Address:" "$address" "[Ctrl+$key]"
        ((field_num++))
    fi

    # Passport number (hidden)
    passport=$(echo "$json" | jq -r '.data.passport_number // empty')
    if [[ -n "$passport" ]]; then
        key="${keys[$field_num]}"
        print_field "$YELLOW" "Passport:" "••••••••" "[Ctrl+$key]"
        ((field_num++))
    fi

    # License number
    license=$(echo "$json" | jq -r '.data.license_number // empty')
    if [[ -n "$license" ]]; then
        key="${keys[$field_num]}"
        print_field "$GREEN" "License:" "$license" "[Ctrl+$key]"
        ((field_num++))
    fi

elif [[ -n "$cardholder_name" ]]; then
    # CARD ENTRY

    # Card number (hidden) - Enter key for cards
    card_number=$(echo "$json" | jq -r '.data.number // empty')
    if [[ -n "$card_number" ]]; then
        print_field "$YELLOW" "Number:" "•••• •••• •••• ••••" "[Enter]"
    fi

    # Cardholder name
    key="${keys[$field_num]}"
    print_field "$GREEN" "Cardholder:" "$cardholder_name" "[Ctrl+$key]"
    ((field_num++))

    # Expiration
    exp_month=$(echo "$json" | jq -r '.data.exp_month // empty')
    exp_year=$(echo "$json" | jq -r '.data.exp_year // empty')
    if [[ -n "$exp_month" && -n "$exp_year" ]]; then
        key="${keys[$field_num]}"
        print_field "$BLUE" "Expiration:" "$exp_month / $exp_year" "[Ctrl+$key]"
        ((field_num++))
    fi

    # Security code (CVV)
    code=$(echo "$json" | jq -r '.data.code // empty')
    if [[ -n "$code" ]]; then
        key="${keys[$field_num]}"
        print_field "$MAGENTA" "CVV:" "•••" "[Ctrl+$key]"
        ((field_num++))
    fi

else
    # LOGIN ENTRY

    # Password (always first - Enter key)
    password=$(echo "$json" | jq -r '.data.password // empty')
    if [[ -n "$password" ]]; then
        print_field "$YELLOW" "Password:" "••••••••" "[Enter]"
    fi

    # Username
    username=$(echo "$json" | jq -r '.data.username // empty')
    if [[ -n "$username" ]]; then
        key="${keys[$field_num]}"
        print_field "$GREEN" "Username:" "$username" "[Ctrl+$key]"
        ((field_num++))
    fi

    # URIs
    uris=$(echo "$json" | jq -r '.data.uris[]?.uri // empty' 2>/dev/null | head -1)
    if [[ -n "$uris" ]]; then
        key="${keys[$field_num]}"
        print_field "$BLUE" "Website:" "$uris" "[Ctrl+$key]"
        ((field_num++))
    fi

    # TOTP
    totp=$(echo "$json" | jq -r '.data.totp // empty')
    if [[ -n "$totp" ]]; then
        key="${keys[$field_num]}"
        print_field "$MAGENTA" "TOTP:" "Enabled" "[Ctrl+$key]"
        ((field_num++))
    fi
fi

# Custom fields (common to all types)
custom_fields=$(echo "$json" | jq -c '.fields[]? // empty' 2>/dev/null)
if [[ -n "$custom_fields" ]]; then
    add_line ""
    add_line "${CYAN}Custom Fields:${RESET}"
    while IFS= read -r field; do
        if [[ -n "$field" && $field_num -lt ${#keys[@]} ]]; then
            name=$(echo "$field" | jq -r '.name')
            value=$(echo "$field" | jq -r '.value // empty')
            field_type=$(echo "$field" | jq -r '.type // "text"')

            # Hide value if type is "hidden"
            if [[ "$field_type" == "hidden" ]]; then
                display_value="•••••••"
            else
                display_value="$value"
            fi

            key="${keys[$field_num]}"

            # Print with custom field indentation
            text="  $name: $display_value"
            padding=$((COL_WIDTH - ${#text}))
            spaces=$(printf '%*s' "$padding" '')

            add_line "  ${BLUE}$name:${RESET} ${display_value}${spaces}${GREEN}[Ctrl+$key]${RESET}"
            ((field_num++))
        fi
    done <<< "$custom_fields"
fi

# Notes
notes=$(echo "$json" | jq -r '.notes // empty')
if [[ -n "$notes" ]]; then
    add_line ""
    add_line "${MAGENTA}Notes:${RESET}"
    add_line "$notes"
fi

# Calculate padding to push navigation to bottom
terminal_lines=$(tput lines 2>/dev/null || echo 40)
preview_height=$((terminal_lines / 2 - 3))

# Count actual content lines
content_lines=$(echo -n "$content" | wc -l)
footer_lines=2

# Calculate padding needed
padding_lines=$((preview_height - content_lines - footer_lines))
if [[ $padding_lines -lt 0 ]]; then
    padding_lines=0
fi

# Print content
echo -e "$content"

# Add padding
for ((i=0; i<padding_lines; i++)); do
    echo ""
done

# Footer at bottom
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GRAY}Navigation: ${RESET}${GREEN}Ctrl+P/N${RESET} up/down  ${GREEN}Ctrl+/${RESET} toggle  ${GREEN}Ctrl+O${RESET} open URL  ${GREEN}Ctrl+S${RESET} sort"
