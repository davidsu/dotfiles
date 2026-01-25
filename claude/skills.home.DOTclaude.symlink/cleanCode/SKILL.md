---
name: cleanCode
description: Refactor/clean/simplify code - eliminate duplication, small functions, readable names. USE WHEN user says "clean", "simplify", "refactor", "readable", "messy", "complex", or code has >15 line functions or copy-paste.
---

# Code Simplification Pass

After getting code working, run mandatory refactoring checklist.

## Core Principle: Code Reads Like English

The ultimate test: **Can someone read the code like prose and understand what it does?**

```bash
# Bad: Requires decoding
if [[ -n $(echo "$json" | jq -r '.data.first_name // empty') ]]; then

# Good: Reads like English
if is_identity_entry "$json"; then
```

Function names should be so clear that you rarely need comments.

## 1. Small Functions with Descriptive Names

**Target: 3-10 lines per function.** If a function is >15 lines, it's doing too much.

Each function should do **one thing** and have a name that explains that thing:

```javascript
// Bad: Generic name, does multiple things
function process(filename) {
  const ext = filename.replace(/.*symlink/, '');
  const base = filename.replace(/\.symlink.*$/, '');
  const name = base.replace(/DOT/g, '.');
  // ... 20 more lines
}

// Good: Small functions with clear names
const extractExtension = (filename) => filename.replace(/.*symlink/, '');
const removeSymlinkAndExtension = (filename) => filename.replace(/\.symlink.*$/, '');
const replaceDOTWithDot = (str) => str.replace(/DOT/g, '.');
```

**Naming rules:**
- Use full words, no abbreviations: `handleExistingFile()` not `handleFile()`
- Verbs for actions: `createLink()`, `validate()`, `render()`
- Boolean checks: `is...()`, `has...()`, `can...()`
- No generic names: `process()`, `handle()`, `do()` → What specifically?

## 2. Duplication Smell

If you copy-paste code, stop immediately. Extract a function.

**Pattern to spot:** Multiple blocks with similar structure doing slightly different things.

```bash
# Bad: Repeated pattern across 3 entry types
# Identity block: 40 lines of field extraction + printing
# Card block: 35 lines of field extraction + printing
# Login block: 30 lines of field extraction + printing

# Good: Extract the common pattern
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

# Now each entry type is clean
render_login_entry() {
    render_login_password "$json"
    print_field_if_present "$json" '.data.username' "$GREEN" "Username:"
    print_field_if_present "$json" '.data.email' "$BLUE" "Email:"
}
```

## 3. False Dichotomy Check

Question whether branches represent truly different cases or missing abstraction.

Ask: **"What if I handle both cases uniformly?"**

```javascript
// Bad: Special casing
if (hasExtension) {
  return transformWithExtension(filename);
} else {
  return transformWithoutExtension(filename);
}

// Good: Uniform handling (extension can be empty string)
const extension = extractExtension(filename);
const base = removeSymlinkAndExtension(filename);
return `${transformBase(base)}${extension}`;
```

## 4. Composition Over Branching

Prefer composing small functions over large conditional blocks.

**Pipeline pattern:** extract → transform → combine

```javascript
// Bad: One big function with branches
function transformPath(filename) {
  if (condition1) {
    // 10 lines
  } else if (condition2) {
    // 10 lines
  } else {
    // 10 lines
  }
}

// Good: Compose small functions
function transformPath(filename) {
  if (!/\.home/.test(filename)) return null;

  const extension = extractExtension(filename);
  const base = removeSymlinkAndExtension(filename);
  const name = extractName(base);
  const directory = extractDirectory(base);

  return `${HOME}${directory}/${name}${extension}`;
}
```

Each line reads like English, describing **what** not **how**.

## 5. Type-Based Dispatch

When you have multiple "types" with different behavior, use clear routing:

```bash
# Bad: Nested conditionals
if [[ -n "$first_name" ]]; then
    # 50 lines of identity logic
elif [[ -n "$cardholder" ]]; then
    # 40 lines of card logic
else
    # 35 lines of login logic
fi

# Good: Separate functions + clean dispatch
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
```

## 6. Special Case Elimination

Every "special case" must justify its existence.

**Default to uniform handling.** Only add special cases when unavoidable.

```javascript
// Bad: Unnecessary special case
if (files.length === 1) {
  return handleSingleFile(files[0]);
} else {
  return handleMultipleFiles(files);
}

// Good: Unified handling (works for n=1 too)
return files.map(handleFile);
```

## 7. Complexity Budget

**Hard limits:**
- Function >15 lines → Extract subfunctions
- File >100 lines → Consider splitting by responsibility
- Nested blocks >2 deep → Extract function

If you need to scroll to understand a function, it's too long.

## Refactoring Checklist

Before considering code "done":

1. **Can I read it like English?** Function names should tell the story
2. **Did I copy-paste any code?** Extract to function
3. **Are there parallel if/else blocks?** Extract common pattern
4. **Is any function >15 lines?** Break into subfunctions
5. **Do branches represent real differences?** Try uniform handling
6. **Can I compose small functions instead of branching?** Prefer pipeline
7. **Does every special case justify itself?** Remove if possible

## Self-Prompt

**Before finishing:**

"Are there duplicate patterns? Can special cases be unified? Can I use function composition instead of branching? Does the code read like English?"
