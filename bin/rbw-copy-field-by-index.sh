#!/bin/bash
# Copy a field from rbw entry by index

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
    local current_index="$2"
    local target_index="$3"
    local json_path="$4"
    local label="$5"

    local value=$(get_json_field "$json" "$json_path")
    if [[ -n "$value" && $current_index -eq $target_index ]]; then
        copy_to_clipboard "$value" "$label"
    fi

    [[ -n "$value" ]] && echo "$((current_index + 1))" || echo "$current_index"
}

try_copy_computed_field() {
    local json="$1"
    local current_index="$2"
    local target_index="$3"
    local compute_fn="$4"
    local label="$5"

    local value=$($compute_fn "$json")
    if [[ -n "$value" && $current_index -eq $target_index ]]; then
        copy_to_clipboard "$value" "$label"
    fi

    [[ -n "$value" ]] && echo "$((current_index + 1))" || echo "$current_index"
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
    local json="$1"
    local entry="$2"
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
    local field_num="$3"

    field_num=$(try_copy_computed_field "$json" $field_num $index compute_full_name "Name")
    field_num=$(try_copy_field "$json" $field_num $index '.data.email' "Email")
    field_num=$(try_copy_field "$json" $field_num $index '.data.phone' "Phone")
    field_num=$(try_copy_computed_field "$json" $field_num $index compute_full_address "Address")
    field_num=$(try_copy_field "$json" $field_num $index '.data.passport_number' "Passport number")
    field_num=$(try_copy_field "$json" $field_num $index '.data.license_number' "License number")

    echo "$field_num"
}

process_card_fields() {
    local json="$1"
    local index="$2"
    local field_num="$3"

    field_num=$(try_copy_field "$json" $field_num $index '.data.cardholder_name' "Cardholder name")
    field_num=$(try_copy_field "$json" $field_num $index '.data.number' "Card number")
    field_num=$(try_copy_computed_field "$json" $field_num $index compute_expiration "Expiration date")
    field_num=$(try_copy_field "$json" $field_num $index '.data.code' "CVV")

    echo "$field_num"
}

process_login_fields() {
    local json="$1"
    local index="$2"
    local field_num="$3"
    local entry="$4"

    field_num=$(try_copy_field "$json" $field_num $index '.data.username' "Username")

    local uri=$(get_json_field "$json" '.data.uris[]?.uri' | head -1)
    if [[ -n "$uri" && $field_num -eq $index ]]; then
        copy_to_clipboard "$uri" "Website URL"
    fi
    [[ -n "$uri" ]] && ((field_num++))

    local totp_code=$(compute_totp_code "$json" "$entry")
    if [[ -n "$totp_code" && $field_num -eq $index ]]; then
        copy_to_clipboard "$totp_code" "TOTP code"
    fi
    [[ -n "$totp_code" ]] && ((field_num++))

    echo "$field_num"
}

process_custom_fields() {
    local json="$1"
    local index="$2"
    local field_num="$3"

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

    local field_num=1

    if is_identity_entry "$json"; then
        field_num=$(process_identity_fields "$json" "$index" "$field_num")
    elif is_card_entry "$json"; then
        field_num=$(process_card_fields "$json" "$index" "$field_num")
    else
        field_num=$(process_login_fields "$json" "$index" "$field_num" "$entry")
    fi

    process_custom_fields "$json" "$index" "$field_num"

    exit 1
}

main "$@"
