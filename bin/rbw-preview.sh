#!/bin/bash
# Preview script for rbw entries with numbered fields

# ============================================================================
# Configuration
# ============================================================================

COLUMN_WIDTH=60

KEYS=(b f g h i j m q v x B F G H I J M Q V X)
field_number=0

content=""

# ============================================================================
# Colors
# ============================================================================

define_colors() {
    CYAN='\033[1;36m'
    YELLOW='\033[33m'
    GREEN='\033[32m'
    BLUE='\033[36m'
    MAGENTA='\033[35m'
    GRAY='\033[90m'
    RESET='\033[0m'
}

# ============================================================================
# Content Building
# ============================================================================

add_line() {
    content+="$1"$'\n'
}

add_blank_line() {
    add_line ""
}

# ============================================================================
# Field Rendering
# ============================================================================

get_next_keybind() {
    local key="${KEYS[$field_number]}"
    ((field_number++))
    echo "Ctrl+$key"
}

calculate_padding() {
    local text="$1"
    local padding=$((COLUMN_WIDTH - ${#text}))
    printf '%*s' "$padding" ''
}

print_field() {
    local color="$1"
    local label="$2"
    local value="$3"
    local keybind="$4"

    local text="$label $value"
    local spaces=$(calculate_padding "$text")

    add_line "${color}${label}${RESET} ${value}${spaces}${GREEN}${keybind}${RESET}"
}

print_field_with_next_keybind() {
    local color="$1"
    local label="$2"
    local value="$3"

    local keybind=$(get_next_keybind)
    print_field "$color" "$label" "$value" "[$keybind]"
}

print_field_if_present() {
    local json="$1"
    local json_path="$2"
    local color="$3"
    local label="$4"

    local value=$(echo "$json" | jq -r "$json_path // empty")
    if [[ -n "$value" ]]; then
        print_field_with_next_keybind "$color" "$label" "$value"
    fi
}

print_hidden_field() {
    local color="$1"
    local label="$2"
    local keybind="$3"
    local mask="${4:-••••••••}"

    print_field "$color" "$label" "$mask" "$keybind"
}

# ============================================================================
# Entry Type Detection
# ============================================================================

is_identity_entry() {
    local json="$1"
    local first_name=$(echo "$json" | jq -r '.data.first_name // empty')
    [[ -n "$first_name" ]]
}

is_card_entry() {
    local json="$1"
    local cardholder=$(echo "$json" | jq -r '.data.cardholder_name // empty')
    [[ -n "$cardholder" ]]
}

# ============================================================================
# Identity Entry
# ============================================================================

render_identity_name() {
    local json="$1"
    local first_name=$(echo "$json" | jq -r '.data.first_name // empty')
    local last_name=$(echo "$json" | jq -r '.data.last_name // empty')
    local full_name="$first_name${last_name:+ $last_name}"

    print_field_with_next_keybind "$GREEN" "Name:" "$full_name"
}

render_identity_address() {
    local json="$1"
    local address1=$(echo "$json" | jq -r '.data.address1 // empty')
    local city=$(echo "$json" | jq -r '.data.city // empty')

    if [[ -z "$address1" && -z "$city" ]]; then
        return
    fi

    local state=$(echo "$json" | jq -r '.data.state // empty')
    local postal=$(echo "$json" | jq -r '.data.postal_code // empty')
    local country=$(echo "$json" | jq -r '.data.country // empty')

    local parts=()
    [[ -n "$address1" ]] && parts+=("$address1")
    [[ -n "$city" ]] && parts+=("$city")
    [[ -n "$state" ]] && parts+=("$state")
    [[ -n "$postal" ]] && parts+=("$postal")
    [[ -n "$country" ]] && parts+=("$country")

    local address=$(IFS=", "; echo "${parts[*]}")
    print_field_with_next_keybind "$CYAN" "Address:" "$address"
}

render_identity_passport() {
    local json="$1"
    local passport=$(echo "$json" | jq -r '.data.passport_number // empty')

    if [[ -n "$passport" ]]; then
        print_field_with_next_keybind "$YELLOW" "Passport:" "••••••••"
    fi
}

render_identity_entry() {
    local json="$1"

    render_identity_name "$json"
    print_field_if_present "$json" '.data.email' "$BLUE" "Email:"
    print_field_if_present "$json" '.data.phone' "$MAGENTA" "Phone:"
    render_identity_address "$json"
    render_identity_passport "$json"
    print_field_if_present "$json" '.data.license_number' "$GREEN" "License:"
}

# ============================================================================
# Card Entry
# ============================================================================

render_card_number() {
    local json="$1"
    local card_number=$(echo "$json" | jq -r '.data.number // empty')

    if [[ -n "$card_number" ]]; then
        print_hidden_field "$YELLOW" "Number:" "[Enter]" "•••• •••• •••• ••••"
    fi
}

render_card_expiration() {
    local json="$1"
    local exp_month=$(echo "$json" | jq -r '.data.exp_month // empty')
    local exp_year=$(echo "$json" | jq -r '.data.exp_year // empty')

    if [[ -n "$exp_month" && -n "$exp_year" ]]; then
        print_field_with_next_keybind "$BLUE" "Expiration:" "$exp_month / $exp_year"
    fi
}

render_card_cvv() {
    local json="$1"
    local code=$(echo "$json" | jq -r '.data.code // empty')

    if [[ -n "$code" ]]; then
        print_field_with_next_keybind "$MAGENTA" "CVV:" "•••"
    fi
}

render_card_entry() {
    local json="$1"

    render_card_number "$json"
    print_field_if_present "$json" '.data.cardholder_name' "$GREEN" "Cardholder:"
    render_card_expiration "$json"
    render_card_cvv "$json"
}

# ============================================================================
# Login Entry
# ============================================================================

render_login_password() {
    local json="$1"
    local password=$(echo "$json" | jq -r '.data.password // empty')

    if [[ -n "$password" ]]; then
        print_hidden_field "$YELLOW" "Password:" "[Enter]"
    fi
}

render_login_website() {
    local json="$1"
    local uri=$(echo "$json" | jq -r '.data.uris[]?.uri // empty' 2>/dev/null | head -1)

    if [[ -n "$uri" ]]; then
        print_field_with_next_keybind "$BLUE" "Website:" "$uri"
    fi
}

render_login_totp() {
    local json="$1"
    local totp=$(echo "$json" | jq -r '.data.totp // empty')

    if [[ -n "$totp" ]]; then
        print_field_with_next_keybind "$MAGENTA" "TOTP:" "Enabled"
    fi
}

render_login_entry() {
    local json="$1"

    render_login_password "$json"
    print_field_if_present "$json" '.data.username' "$GREEN" "Username:"
    render_login_website "$json"
    render_login_totp "$json"
}

# ============================================================================
# Common Sections
# ============================================================================

render_custom_fields() {
    local json="$1"
    local custom_fields=$(echo "$json" | jq -c '.fields[]? // empty' 2>/dev/null)

    if [[ -z "$custom_fields" ]]; then
        return
    fi

    add_blank_line
    add_line "${CYAN}Custom Fields:${RESET}"

    while IFS= read -r field; do
        if [[ -z "$field" || $field_number -ge ${#KEYS[@]} ]]; then
            continue
        fi

        local name=$(echo "$field" | jq -r '.name')
        local value=$(echo "$field" | jq -r '.value // empty')
        local field_type=$(echo "$field" | jq -r '.type // "text"')

        local display_value="$value"
        if [[ "$field_type" == "hidden" ]]; then
            display_value="•••••••"
        fi

        local keybind=$(get_next_keybind)
        local text="  $name: $display_value"
        local spaces=$(calculate_padding "$text")

        add_line "  ${BLUE}$name:${RESET} ${display_value}${spaces}${GREEN}[Ctrl+$keybind]${RESET}"
    done <<< "$custom_fields"
}

render_notes() {
    local json="$1"
    local notes=$(echo "$json" | jq -r '.notes // empty')

    if [[ -n "$notes" ]]; then
        add_blank_line
        add_line "${MAGENTA}Notes:${RESET}"
        add_line "$notes"
    fi
}

render_header() {
    local entry_name="$1"
    add_line "${CYAN}━━━ $entry_name ━━━${RESET}"
    add_blank_line
}

render_footer() {
    local terminal_lines=$(tput lines 2>/dev/null || echo 40)
    local preview_height=$((terminal_lines / 2 - 3))
    local content_lines=$(echo -n "$content" | wc -l)
    local footer_lines=2
    local padding_lines=$((preview_height - content_lines - footer_lines))

    if [[ $padding_lines -lt 0 ]]; then
        padding_lines=0
    fi

    echo -e "$content"

    for ((i=0; i<padding_lines; i++)); do
        echo ""
    done

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GRAY}Navigation: ${RESET}${GREEN}Ctrl+P/N${RESET} up/down  ${GREEN}Ctrl+/${RESET} toggle  ${GREEN}Ctrl+O${RESET} open URL  ${GREEN}Ctrl+S${RESET} sort"
}

# ============================================================================
# Entry Routing
# ============================================================================

render_entry_fields() {
    local json="$1"

    if is_identity_entry "$json"; then
        render_identity_entry "$json"
    elif is_card_entry "$json"; then
        render_card_entry "$json"
    else
        render_login_entry "$json"
    fi
}

# ============================================================================
# Main
# ============================================================================

fetch_entry_json() {
    local entry_name="$1"
    rbw get "$entry_name" --raw 2>/dev/null
}

validate_entry_name() {
    local entry_name="$1"

    if [[ -z "$entry_name" ]]; then
        echo "No entry selected"
        exit 0
    fi
}

validate_entry_json() {
    local json="$1"

    if [[ -z "$json" ]]; then
        echo "Failed to fetch entry"
        exit 0
    fi
}

print_preview() {
    local entry_name="$1"

    validate_entry_name "$entry_name"

    local json=$(fetch_entry_json "$entry_name")
    validate_entry_json "$json"

    define_colors

    render_header "$entry_name"
    render_entry_fields "$json"
    render_custom_fields "$json"
    render_notes "$json"
    render_footer
}

print_preview "$1"
