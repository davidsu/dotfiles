---
name: bash-refactoring
description: Bash/shell-specific refactoring knowledge - gotchas, patterns, and anti-patterns for shell scripts
---

# Bash Refactoring Guide

## Critical Bash Gotchas

### Subshells Break State Modifications

**Command substitution `$(...)` creates a subshell.** The subshell gets a copy of variables. Changes in the subshell are lost.

```bash
# BROKEN: field_num never increments in parent shell
get_next_key() {
    echo "${KEYS[$field_num]}"
    ((field_num++))  # Only affects subshell copy!
}
key=$(get_next_key)  # field_num unchanged in parent
```

**Fix options:**

1. **Inline the logic** (best for simple cases):
```bash
key="${KEYS[$field_num]}"
((field_num++))
```

2. **Use global state directly** (no command substitution):
```bash
get_next_key() {
    key="${KEYS[$field_num]}"
    ((field_num++))
}
get_next_key  # Modifies parent shell's field_num
```

3. **Return via echo, pass state as parameter**:
```bash
get_next_key() {
    local current_num=$1
    echo "${KEYS[$current_num]}"
}
key=$(get_next_key $field_num)
((field_num++))
```

**Other subshell creators:**
- Pipes: `echo "x" | while read; do counter++; done` (counter unchanged after)
- Background: `command &`
- Explicit: `(command)` with parentheses

### When to Use Functions in Bash

**Use functions when:**
- Logic is used 2+ times (real DRY)
- Complex command that needs a clear name
- Error handling/retry logic
- Encapsulating a multi-step process

**Don't use functions when:**
- Only called once and simple (< 5 lines)
- Function would need to modify parent state AND return a value
- The function name is longer than just doing it directly

### Bash-Specific Testing

Before refactoring bash scripts:

```bash
# Test with actual commands
./script.sh input1 > /tmp/original-output1.txt
./script.sh input2 > /tmp/original-output2.txt

# After refactoring - outputs must match exactly
diff /tmp/original-output1.txt <(./script.sh input1)
diff /tmp/original-output2.txt <(./script.sh input2)
```

## Good Bash Patterns

### Small helper for repeated jq queries
```bash
get_json_field() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "$path // empty"
}

# Now readable:
email=$(get_json_field "$json" '.data.email')
phone=$(get_json_field "$json" '.data.phone')
```

### Conditional field printing
```bash
print_field_if_present() {
    local json="$1"
    local json_path="$2"
    local color="$3"
    local label="$4"

    local value=$(echo "$json" | jq -r "$json_path // empty")
    [[ -z "$value" ]] && return

    print_field "$color" "$label" "$value"
}

# Clean call sites:
print_field_if_present "$json" '.data.email' "$BLUE" "Email:"
print_field_if_present "$json" '.data.phone' "$MAGENTA" "Phone:"
```

### Early returns for clarity
```bash
# Good
process_entry() {
    [[ -z "$entry" ]] && return 1
    [[ ! -f "$file" ]] && return 1
    
    # Main logic here without nesting
}

# Bad - nested pyramids
process_entry() {
    if [[ -n "$entry" ]]; then
        if [[ -f "$file" ]]; then
            # Main logic buried 2 levels deep
        fi
    fi
}
```
