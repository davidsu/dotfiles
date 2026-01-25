#!/bin/bash
# Copy a field from rbw entry by index

field_num=1

copy_to_clipboard() {
    local value="$1"
    local label="$2"
    echo -n "$value" | pbcopy
    echo "✓ $label copied to clipboard"
    exit 0
}

get_json_field() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "$path // empty"
}

try_copy_field() {
    local json="$1"
    local index="$2"
    local json_path="$3"
    local label="$4"

    local value=$(get_json_field "$json" "$json_path")
    [[ -z "$value" ]] && return

    if [[ $field_num -eq $index ]]; then
        copy_to_clipboard "$value" "$label"
    fi

    ((field_num++))
}

try_copy_computed_field() {
    local json="$1"
    local index="$2"
    local compute_fn="$3"
    local label="$4"

    local value=$($compute_fn "$json")
    [[ -z "$value" ]] && return

    if [[ $field_num -eq $index ]]; then
        copy_to_clipboard "$value" "$label"
    fi

    ((field_num++))
}

compute_full_name() {
    local json="$1"
    local first_name=$(get_json_field "$json" '.data.first_name')
    local last_name=$(get_json_field "$json" '.data.last_name')
    echo "$first_name${last_name:+ $last_name}"
}

compute_full_address() {
    local json="$1"
    local addr_parts=()

    for field in address1 city state postal_code country; do
        local value=$(get_json_field "$json" ".data.$field")
        [[ -n "$value" ]] && addr_parts+=("$value")
    done

    [[ ${#addr_parts[@]} -gt 0 ]] && (IFS=", "; echo "${addr_parts[*]}")
}

compute_expiration() {
    local json="$1"
    local month=$(get_json_field "$json" '.data.exp_month')
    local year=$(get_json_field "$json" '.data.exp_year')
    [[ -n "$month" && -n "$year" ]] && echo "$month/$year"
}

compute_totp_code() {
    local entry="$1"
    local json="$2"
    local totp=$(get_json_field "$json" '.data.totp')
    [[ -n "$totp" ]] && rbw code "$entry" 2>/dev/null
}

is_identity_entry() {
    local json="$1"
    [[ -n $(get_json_field "$json" '.data.first_name') ]]
}

is_card_entry() {
    local json="$1"
    [[ -n $(get_json_field "$json" '.data.cardholder_name') ]]
}

process_identity_fields() {
    local json="$1"
    local index="$2"

    try_copy_computed_field "$json" "$index" compute_full_name "Name"
    try_copy_field "$json" "$index" '.data.email' "Email"
    try_copy_field "$json" "$index" '.data.phone' "Phone"
    try_copy_computed_field "$json" "$index" compute_full_address "Address"
    try_copy_field "$json" "$index" '.data.passport_number' "Passport number"
    try_copy_field "$json" "$index" '.data.license_number' "License number"
}

process_card_fields() {
    local json="$1"
    local index="$2"

    try_copy_field "$json" "$index" '.data.cardholder_name' "Cardholder name"
    try_copy_field "$json" "$index" '.data.number' "Card number"
    try_copy_computed_field "$json" "$index" compute_expiration "Expiration date"
    try_copy_field "$json" "$index" '.data.code' "CVV"
}

process_login_fields() {
    local json="$1"
    local index="$2"
    local entry="$3"

    try_copy_field "$json" "$index" '.data.username' "Username"

    local uri=$(get_json_field "$json" '.data.uris[]?.uri' | head -1)
    if [[ -n "$uri" ]]; then
        if [[ $field_num -eq $index ]]; then
            copy_to_clipboard "$uri" "Website URL"
        fi
        ((field_num++))
    fi

    local totp_code=$(compute_totp_code "$entry" "$json")
    if [[ -n "$totp_code" ]]; then
        if [[ $field_num -eq $index ]]; then
            copy_to_clipboard "$totp_code" "TOTP code"
        fi
        ((field_num++))
    fi
}

process_custom_fields() {
    local json="$1"
    local index="$2"

    local custom_fields=$(echo "$json" | jq -c '.fields[]? // empty' 2>/dev/null)
    [[ -z "$custom_fields" ]] && return

    while IFS= read -r field; do
        [[ -z "$field" ]] && continue

        if [[ $field_num -eq $index ]]; then
            local name=$(echo "$field" | jq -r '.name')
            local value=$(echo "$field" | jq -r '.value // empty')
            copy_to_clipboard "$value" "$name"
        fi
        ((field_num++))
    done <<< "$custom_fields"
}

main() {
    local entry="$1"
    local index="$2"

    [[ -z "$entry" || -z "$index" ]] && exit 1

    local json=$(rbw get "$entry" --raw 2>/dev/null)
    [[ -z "$json" ]] && exit 1

    if is_identity_entry "$json"; then
        process_identity_fields "$json" "$index"
    elif is_card_entry "$json"; then
        process_card_fields "$json" "$index"
    else
        process_login_fields "$json" "$index" "$entry"
    fi

    process_custom_fields "$json" "$index"

    exit 1
}

main "$@"
