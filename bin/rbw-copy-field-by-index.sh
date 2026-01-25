#!/bin/bash
# Copy a field from rbw entry by index
# Handles both login and card entries

entry="$1"
index="$2"

if [[ -z "$entry" || -z "$index" ]]; then
    exit 1
fi

# Get raw JSON
json=$(rbw get "$entry" --raw 2>/dev/null)
if [[ -z "$json" ]]; then
    exit 1
fi

field_num=1

# Detect entry type (identity, card, or login)
first_name=$(echo "$json" | jq -r '.data.first_name // empty')
cardholder_name=$(echo "$json" | jq -r '.data.cardholder_name // empty')

if [[ -n "$first_name" ]]; then
    # IDENTITY ENTRY

    # Full name
    last_name=$(echo "$json" | jq -r '.data.last_name // empty')
    full_name="$first_name${last_name:+ $last_name}"
    if [[ $field_num -eq $index ]]; then
        echo -n "$full_name" | pbcopy
        echo "✓ Name copied to clipboard"
        exit 0
    fi
    ((field_num++))

    # Email
    email=$(echo "$json" | jq -r '.data.email // empty')
    if [[ -n "$email" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$email" | pbcopy
            echo "✓ Email copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # Phone
    phone=$(echo "$json" | jq -r '.data.phone // empty')
    if [[ -n "$phone" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$phone" | pbcopy
            echo "✓ Phone copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # Address
    address1=$(echo "$json" | jq -r '.data.address1 // empty')
    city=$(echo "$json" | jq -r '.data.city // empty')
    if [[ -n "$address1" || -n "$city" ]]; then
        if [[ $field_num -eq $index ]]; then
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
            echo -n "$address" | pbcopy
            echo "✓ Address copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # Passport number
    passport=$(echo "$json" | jq -r '.data.passport_number // empty')
    if [[ -n "$passport" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$passport" | pbcopy
            echo "✓ Passport number copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # License number
    license=$(echo "$json" | jq -r '.data.license_number // empty')
    if [[ -n "$license" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$license" | pbcopy
            echo "✓ License number copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

elif [[ -n "$cardholder_name" ]]; then
    # CARD ENTRY

    # Cardholder name
    if [[ $field_num -eq $index ]]; then
        echo -n "$cardholder_name" | pbcopy
        echo "✓ Cardholder name copied to clipboard"
        exit 0
    fi
    ((field_num++))

    # Card number
    card_number=$(echo "$json" | jq -r '.data.number // empty')
    if [[ -n "$card_number" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$card_number" | pbcopy
            echo "✓ Card number copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # Expiration (MM/YYYY format)
    exp_month=$(echo "$json" | jq -r '.data.exp_month // empty')
    exp_year=$(echo "$json" | jq -r '.data.exp_year // empty')
    if [[ -n "$exp_month" && -n "$exp_year" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$exp_month/$exp_year" | pbcopy
            echo "✓ Expiration date copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # CVV/Security code
    code=$(echo "$json" | jq -r '.data.code // empty')
    if [[ -n "$code" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$code" | pbcopy
            echo "✓ CVV copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

else
    # LOGIN ENTRY

    # Username
    username=$(echo "$json" | jq -r '.data.username // empty')
    if [[ -n "$username" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$username" | pbcopy
            echo "✓ Username copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # Website (copy URL)
    uris=$(echo "$json" | jq -r '.data.uris[]?.uri // empty' 2>/dev/null | head -1)
    if [[ -n "$uris" ]]; then
        if [[ $field_num -eq $index ]]; then
            echo -n "$uris" | pbcopy
            echo "✓ Website URL copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi

    # TOTP
    totp=$(echo "$json" | jq -r '.data.totp // empty')
    if [[ -n "$totp" ]]; then
        if [[ $field_num -eq $index ]]; then
            rbw code "$entry" 2>/dev/null | pbcopy
            echo "✓ TOTP code copied to clipboard"
            exit 0
        fi
        ((field_num++))
    fi
fi

# Custom fields (common to all types)
custom_fields=$(echo "$json" | jq -c '.fields[]? // empty' 2>/dev/null)
if [[ -n "$custom_fields" ]]; then
    while IFS= read -r field; do
        if [[ -n "$field" ]]; then
            if [[ $field_num -eq $index ]]; then
                name=$(echo "$field" | jq -r '.name')
                value=$(echo "$field" | jq -r '.value // empty')
                echo -n "$value" | pbcopy
                echo "✓ $name copied to clipboard"
                exit 0
            fi
            ((field_num++))
        fi
    done <<< "$custom_fields"
fi

exit 1
