---
name: cleanCode
description: Refactor/clean/simplify code - eliminate duplication, small functions, readable names. USE WHEN user says "clean", "simplify", "refactor", "readable", "messy", "complex", or code has >15 line functions or copy-paste.
---

# Code Simplification Pass

After getting code working, run mandatory refactoring checklist.

**Influences:** This skill draws from Douglas Crockford's "JavaScript: The Good Parts" (favor simplicity, avoid unnecessary features) and Robert C. Martin's "Clean Code" (readable names, small functions, single responsibility).

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

**Target: 3-10 lines per function.** If a function is >20 lines, it's doing too much.

Each function should do **one thing** and have a name that explains that thing:

```javascript
// Bad: Generic name, does multiple things
function process(filename) {
  const ext = filename.replace(/.*symlink/, "");
  const base = filename.replace(/\.symlink.*$/, "");
  const name = base.replace(/DOT/g, ".");
  // ... 20 more lines
}

// Good: Small functions with clear names
const extractExtension = (filename) => filename.replace(/.*symlink/, "");
const removeSymlinkAndExtension = (filename) =>
  filename.replace(/\.symlink.*$/, "");
const replaceDOTWithDot = (str) => str.replace(/DOT/g, ".");
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

## 5. Eliminate Type Dispatch - Iterate the Source

**Red flag:** Multiple `extractTypeA()`, `extractTypeB()`, `extractTypeC()` functions doing similar field extraction.

**Pattern to recognize:**
```javascript
// Bad: Type-specific extractors
const extractIdentityFields = (json) => {
  const fields = [];
  if (json.data.first_name) fields.push({label: 'Name:', value: json.data.first_name});
  if (json.data.email) fields.push({label: 'Email:', value: json.data.email});
  // ... 10 more lines
  return fields;
};

const extractCardFields = (json) => {
  const fields = [];
  if (json.data.number) fields.push({label: 'Number:', value: '••••'});
  if (json.data.cardholder_name) fields.push({label: 'Cardholder:', value: json.data.cardholder_name});
  // ... 8 more lines
  return fields;
};

const extractLoginFields = (json) => {
  // ... another variant
};

// Type dispatch
if (isIdentity(json)) return extractIdentityFields(json);
if (isCard(json)) return extractCardFields(json);
return extractLoginFields(json);
```

**Solution: Iterate the source data structure directly**

Instead of hardcoding which fields to extract for each type, iterate over what exists:

```javascript
// Good: Generic extraction - no type checking needed
const extractData = (json) =>
  Object.entries(json.data || {})
    .filter(([key, value]) => value && typeof value === 'string')
    .map(([key, value]) => ({
      label: humanizeKey(key),                    // username → "Username:"
      displayValue: shouldMask(key) ? mask(key) : value,
      keybind: shouldMask(key) ? '[Enter]' : nextKey()
    }));

const extractFields = (json) =>
  (json.fields || []).map(field => ({
    label: field.name + ':',
    displayValue: field.type === 'hidden' ? '•••' : field.value,
    keybind: field.type === 'hidden' ? '[Enter]' : nextKey()
  }));

// No type dispatch - just merge and render
const entries = [...extractData(json), ...extractFields(json)];
for (const entry of entries) {
  printField(entry.displayValue, entry.label, entry.keybind);
}
```

**Why this works:**
- Identity entries have `{first_name, last_name, email}` → extracted
- Card entries have `{number, cardholder_name, exp_month}` → extracted
- Login entries have `{username, password}` → extracted
- All normalized to `{label, displayValue, keybind}` → same rendering

**The cookbook pattern:**
1. You have: `extractTypeA`, `extractTypeB`, `extractTypeC` doing similar work
2. Replace with: `Object.entries(source)` + `.map()` to normalize
3. Result: One extractor, no type checking

**Key insight:** Don't ask "what type is this?" Ask "what data exists?" Iterate the source, normalize the structure, process uniformly.

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

## 7. Question Every Wrapper

If a function is only called once, inline it. Don't create wrappers "for organization."

```javascript
// Bad: Unnecessary wrapper
const renderEntry = (renderer, entries, name) => {
  renderer.addLine(name);
  for (const entry of entries) {
    renderer.printField(entry);
  }
};

const main = () => {
  const renderer = createRenderer();
  renderEntry(renderer, entries, name); // Only called once
};

// Good: Inline it
const main = () => {
  addLine(name);
  for (const entry of entries) {
    printField(entry);
  }
};
```

**Same for factories:** If you're creating an object just to call its methods once, you don't need a factory. Use module-level state for one-shot scripts.

```javascript
// Bad: Factory for one-shot script
const createRenderer = () => {
  const content = [];
  return {
    addLine: (line) => content.push(line),
    render: () => console.log(content.join('\n'))
  };
};

// Good: Module-level state
const content = [];
const addLine = (line) => content.push(line);
const render = () => console.log(content.join('\n'));
```

## 8. Side Effects: for...of, Not forEach

Use `for...of` for side effects, not `forEach`. `forEach` implies functional/no side effects.

```javascript
// Bad: forEach for side effects (confusing)
entries.forEach(entry => {
  printField(entry); // Side effect!
});

// Good: for...of makes side effects clear
for (const entry of entries) {
  printField(entry);
}
```

## 9. Complexity Budget

**Hard limits:**

- Function >25 lines → Extract subfunctions
- File >100 lines → Consider splitting by responsibility (but not prematurely!)
- Nested blocks >2 deep → Extract function

If you need to scroll to understand a function, it's too long.

**But:** Don't split files just to split them. A focused 200-line file is better than 5 poorly-abstracted 40-line files.

## Refactoring Checklist

Before considering code "done":

1. **Can I read it like English?** Function names should tell the story
2. **Did I copy-paste any code?** Extract to function
3. **Are there parallel if/else blocks?** Extract common pattern or normalize data
4. **Is any function >20 lines?** Break into subfunctions
5. **Do I have multiple extractType functions?** Replace with `Object.entries(source).map()` pattern
6. **Do I have type dispatch (if/else on types)?** Iterate the source data instead
7. **Is this wrapper called only once?** Inline it
8. **Am I using a factory for a one-shot script?** Use module-level state
9. **Am I using forEach for side effects?** Use for...of instead
10. **Does every special case justify itself?** Remove if possible

## Self-Prompt

**Before finishing:**

"Do I have extractTypeA/B/C functions? Can I use Object.entries(source) instead? Are wrappers/factories necessary, or ceremony? Do I have side effects with forEach instead of for...of? Does the code read like English?"
