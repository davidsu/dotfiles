#!/bin/bash
# Preview script for rbw entries with numbered fields

COLUMN_WIDTH=60
KEYS=(b f g h i j m q v x B F G H I J M Q V X)
field_number=0
content=""

CYAN='\033[1;36m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[36m'
MAGENTA='\033[35m'
GRAY='\033[90m'
RESET='\033[0m'

add_line() {
    content+="$1"$'\n'
}

add_blank_line() {
    add_line ""
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

    local key="${KEYS[$field_number]}"
    ((field_number++))
    local keybind="[Ctrl+$key]"

    local text="$label $value"
    local spaces=$(calculate_padding "$text")

    add_line "${color}${label}${RESET} ${value}${spaces}${GREEN}${keybind}${RESET}"
}

print_field_if_present() {
    local json="$1"
    local json_path="$2"
    local color="$3"
    local label="$4"

    local value=$(echo "$json" | jq -r "$json_path // empty")
    [[ -z "$value" ]] && return

    print_field "$color" "$label" "$value"
}

print_hidden_field() {
    local color="$1"
    local label="$2"
    local mask="${3:-••••••••}"

    local text="$label $mask"
    local spaces=$(calculate_padding "$text")

    add_line "${color}${label}${RESET} ${mask}${spaces}${GREEN}[Enter]${RESET}"
}

is_identity_entry() {
    local json="$1"
    [[ -n $(echo "$json" | jq -r '.data.first_name // empty') ]]
}

is_card_entry() {
    local json="$1"
    [[ -n $(echo "$json" | jq -r '.data.cardholder_name // empty') ]]
}

render_identity_entry() {
    local json="$1"

    local first_name=$(echo "$json" | jq -r '.data.first_name // empty')
    local last_name=$(echo "$json" | jq -r '.data.last_name // empty')
    local full_name="$first_name${last_name:+ $last_name}"

    print_field "$GREEN" "Name:" "$full_name"
    print_field_if_present "$json" '.data.email' "$BLUE" "Email:"
    print_field_if_present "$json" '.data.phone' "$MAGENTA" "Phone:"

    local address1=$(echo "$json" | jq -r '.data.address1 // empty')
    local city=$(echo "$json" | jq -r '.data.city // empty')
    if [[ -n "$address1" || -n "$city" ]]; then
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
        print_field "$CYAN" "Address:" "$address"
    fi

    local passport=$(echo "$json" | jq -r '.data.passport_number // empty')
    [[ -n "$passport" ]] && print_field "$YELLOW" "Passport:" "••••••••"

    print_field_if_present "$json" '.data.license_number' "$GREEN" "License:"
}

render_card_entry() {
    local json="$1"

    local card_number=$(echo "$json" | jq -r '.data.number // empty')
    [[ -n "$card_number" ]] && print_hidden_field "$YELLOW" "Number:" "•••• •••• •••• ••••"

    print_field_if_present "$json" '.data.cardholder_name' "$GREEN" "Cardholder:"

    local exp_month=$(echo "$json" | jq -r '.data.exp_month // empty')
    local exp_year=$(echo "$json" | jq -r '.data.exp_year // empty')
    if [[ -n "$exp_month" && -n "$exp_year" ]]; then
        print_field "$BLUE" "Expiration:" "$exp_month / $exp_year"
    fi

    local code=$(echo "$json" | jq -r '.data.code // empty')
    [[ -n "$code" ]] && print_field "$MAGENTA" "CVV:" "•••"
}

render_login_entry() {
    local json="$1"

    local password=$(echo "$json" | jq -r '.data.password // empty')
    [[ -n "$password" ]] && print_hidden_field "$YELLOW" "Password:"

    print_field_if_present "$json" '.data.username' "$GREEN" "Username:"

    local uri=$(echo "$json" | jq -r '.data.uris[]?.uri // empty' 2>/dev/null | head -1)
    [[ -n "$uri" ]] && print_field "$BLUE" "Website:" "$uri"

    local totp=$(echo "$json" | jq -r '.data.totp // empty')
    [[ -n "$totp" ]] && print_field "$MAGENTA" "TOTP:" "Enabled"
}

render_custom_fields() {
    local json="$1"
    local custom_fields=$(echo "$json" | jq -c '.fields[]? // empty' 2>/dev/null)

    [[ -z "$custom_fields" ]] && return

    add_blank_line
    add_line "${CYAN}Custom Fields:${RESET}"

    while IFS= read -r field; do
        [[ -z "$field" || $field_number -ge ${#KEYS[@]} ]] && continue

        local name=$(echo "$field" | jq -r '.name')
        local value=$(echo "$field" | jq -r '.value // empty')
        local field_type=$(echo "$field" | jq -r '.type // "text"')

        local display_value="$value"
        [[ "$field_type" == "hidden" ]] && display_value="•••••••"

        local key="${KEYS[$field_number]}"
        ((field_number++))
        local keybind="[Ctrl+$key]"

        local text="  $name: $display_value"
        local spaces=$(calculate_padding "$text")

        add_line "  ${BLUE}$name:${RESET} ${display_value}${spaces}${GREEN}${keybind}${RESET}"
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

render_footer() {
    local terminal_lines=$(tput lines 2>/dev/null || echo 40)
    local preview_height=$((terminal_lines / 2 - 3))
    local content_lines=$(echo -n "$content" | wc -l)
    local footer_lines=2
    local padding_lines=$((preview_height - content_lines - footer_lines))

    [[ $padding_lines -lt 0 ]] && padding_lines=0

    echo -e "$content"

    for ((i=0; i<padding_lines; i++)); do
        echo ""
    done

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GRAY}Navigation: ${RESET}${GREEN}Ctrl+P/N${RESET} up/down  ${GREEN}Ctrl+/[0m toggle  ${GREEN}Ctrl+O${RESET} open URL  ${GREEN}Ctrl+S${RESET} sort"
}

main() {
    local entry_name="$1"

    if [[ -z "$entry_name" ]]; then
        echo "No entry selected"
        exit 0
    fi

    local json=$(rbw get "$entry_name" --raw 2>/dev/null)
    if [[ -z "$json" ]]; then
        echo "Failed to fetch entry"
        exit 0
    fi

    add_line "${CYAN}━━━ $entry_name ━━━${RESET}"
    add_blank_line

    if is_identity_entry "$json"; then
        render_identity_entry "$json"
    elif is_card_entry "$json"; then
        render_card_entry "$json"
    else
        render_login_entry "$json"
    fi

    render_custom_fields "$json"
    render_notes "$json"
    render_footer
}

main "$@"
