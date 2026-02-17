---
name: cleanCode
description: Refactor/clean/simplify code - eliminate duplication, small functions, readable names. USE WHEN user says "clean", "simplify", "refactor", "readable", "messy", "complex", or code has >15 line functions or copy-paste.
---

# Code Simplification

**Core principle:** Code reads like English prose.

**Influences:** Douglas Crockford's "JavaScript: The Good Parts", Robert C. Martin's "Clean Code"

## Language-Specific Rules

**CRITICAL**: Before writing code, read the relevant resource:

| Language   | Resource                                 |
|------------|------------------------------------------|
| TypeScript | [typescript.md](resources/typescript.md) |
| Bash/Shell | [bash.md](resources/bash.md)             |
| Python     | [python.md](resources/python.md)         |
| Neovim/Lua | [neovim.md](resources/neovim.md)         |

## General Principles

- **Understand before changing** - Read existing code before making modifications
- **Ask for clarity** - When requirements are ambiguous, ask rather than guess
- **Minimize scope** - Only change what's directly requested or clearly necessary
- **Prefer clarity** - Clear code over clever code
- **Skill rules override existing code** - The codebase is inherited and may contain legacy patterns that violate these guidelines. All **new and modified** code must follow the rules here, even if surrounding code doesn't

## 1. Small Functions, Clear Names

**Target: 3-15 lines per function.** Name describes exactly what it does.

```typescript
// Bad: Generic name, does multiple things (40 lines)
function process(filename) { ... }

// Good: Small functions with precise names
const extractExtension = (filename) => filename.replace(/.*symlink/, '')
const removeSymlinkAndExtension = (filename) => filename.replace(/\.symlink.*$/, '')
const replaceDOTWithDot = (str) => str.replace(/DOT/g, '.')
```

**Naming rules:**
- Verbs for actions: `createLink()`, `handleExistingFile()`
- Booleans: `isSymlink()`, `hasExtension()`, `canWrite()`
- No generic names: `process()`, `handle()`, `do()` → What specifically?
- Names should express intent - make the code self-documenting

**Name for the reader at the call site.** Before naming a function, consider who reads the code that *calls* it. Would they understand why this function is being called? A good name makes surrounding code read like prose — the reader shouldn't need to open the function body to understand the flow.

```javascript
// Bad: named for the mechanism (checks an origin allowlist)
// Reader at call site must open the function to understand WHY
if (!isAllowedOrigin(config.url, config.baseURL)) {
    delete config.headers['Authorization'];
}

// Good: named for the decision (is it safe to send credentials here?)
// Call site is self-documenting — you immediately understand the intent
if (!isSafeForAuthHeaders(config.url, config.baseURL)) {
    delete config.headers['Authorization'];
}
```

Note: this applies to functions at **decision points** — guards, predicates, business logic. Low-level utilities and pure transformations (`toHttpOrigin`, `parseJSON`, `normalizeUrl`) are fine named for their mechanism, because callers already know *why* they're calling them.

## 2. No Duplication

If you copy-paste code, stop. Extract a function.

```typescript
// Bad: 3 similar blocks, 40 lines each
function renderIdentity(json) { /* extract fields, print */ }
function renderCard(json) { /* extract fields, print */ }
function renderLogin(json) { /* extract fields, print */ }

// Good: Extract common pattern
function renderEntry(json) {
  const fields = extractFields(json)
  fields.forEach(field => printField(field))
}
```

## 3. Iterate the Source, Not Type Dispatch

**Red flag:** Multiple `extractTypeA()`, `extractTypeB()`, `extractTypeC()` functions.

**Instead:** Iterate the data structure directly.

```javascript
// Bad: Type-specific extractors + dispatch
const extractIdentity = (json) => [/* hardcode identity fields */]
const extractCard = (json) => [/* hardcode card fields */]
const extractLogin = (json) => [/* hardcode login fields */]

if (isIdentity(json)) return extractIdentity(json)
if (isCard(json)) return extractCard(json)
return extractLogin(json)

// Good: Generic extraction - iterate what exists
const extractFields = (json) =>
  Object.entries(json.data || {})
    .filter(([key, value]) => value && typeof value === 'string')
    .map(([key, value]) => ({
      label: humanizeKey(key),
      displayValue: shouldMask(key) ? '•••' : value
    }))

// Works for all types, no type checking
```

**Key insight:** Don't ask "what type is this?" Ask "what data exists?"

## 4. Module Splitting: ~250 Lines

When a file exceeds 250 lines, look for natural module boundaries.

```typescript
// Before: links.ts - 247 lines (path utils + file ops + handlers + class + orchestration)

// After: Split by responsibility
// symlink/path-transform.ts - 23 lines
// symlink/file-ops.ts - 40 lines
// symlink/handlers.ts - 43 lines
// symlink/operation.ts - 76 lines
// links.ts - 77 lines (orchestration only)
```

**Don't split prematurely:** 200-line focused file > 5 poorly-abstracted 40-line files.

**Structure and Organization:**
- Define functions and configuration logic before return/export statements
- Keep return/export blocks clean by referencing named functions rather than inline definitions
- Separate declaration (function definitions) from usage (return/export statements)
- Extract inline configuration functions into named functions defined above the return/export
- This improves readability and makes the module's public interface immediately clear

**Clear APIs:**
- Hide implementation details
- Only expose what's necessary
- Internal helpers should be separate from public functions

## 5. Fluent APIs for Sequential Operations

Chain methods to describe operations in natural language.

```typescript
// Bad: Imperative control flow, needs comments
function safeLink(src: string, dest: string | null) {
  // Handle unparseable destination
  if (!dest) return { ... }

  // Handle existing symlink
  if (isSymlink(dest)) { ... }

  // Handle existing file
  if (fileExists(dest)) { ... }

  // Create symlink
  fs.mkdirSync(...)
  return createLink(src, dest)
}

// Good: Reads like English, no comments needed
const safeLink = (src: string, dest: string | null) =>
  new SymlinkOperation(src, dest)
    .handleNullDestination()
    .handleSymlink()
    .handleExistingFile()
    .createSymlink()
    .result()
```

**Implementation pattern:**
```typescript
class Operation {
  private result: Result | null = null

  step1() {
    if (this.result) return this  // Short-circuit if done
    // Check condition, maybe set this.result
    return this
  }

  result() { return this.result! }
}
```

**When to use:** Sequential operations with decision points, each step is a clear named concern.

## 6. Explicit Failures Over Silent Filtering

Make failures visible with error results, don't silently skip.

```typescript
// Bad: Silent failure - lost information
function buildPlan() {
  return files.map(transformPath).filter(path => path !== null)
}
// Which files failed? Unknown.

// Good: Explicit failure - trackable
function buildPlan() {
  return files.map(file => ({ from: file, to: transformPath(file) }))
}

function executePlan(plan: Array<{from: string, to: string | null}>) {
  return plan.map(({ from, to }) => safeLink(from, to))
}

function safeLink(src: string, dest: string | null) {
  if (!dest) return { from: src, to: '<unparseable>', success: false }
  // ... continue
}

// Now: results.filter(r => !r.success).length shows exactly what failed
```

## 7. Eliminate Special Cases

Every special case must justify its existence. Default to uniform handling.

```javascript
// Bad: Unnecessary special case
if (files.length === 1) {
  return handleSingleFile(files[0])
} else {
  return handleMultipleFiles(files)
}

// Good: Unified handling (works for n=1 too)
return files.map(handleFile)
```

**Ask:** "What if I handle both cases uniformly?"

## 8. Don't Code for Ghosts

Before adding a fallback, guard, or normalization — verify the input can actually take that form. Read the callers. If every caller passes a full URL, don't handle bare hostnames. If the config always returns `https://`, don't branch on `http://`. Dead branches aren't "defensive" — they're noise that misleads readers into thinking those cases are real.

```javascript
// Bad: getAPIUrl() always returns "https://...", bare hostname can't happen
const parsed = /^https?:\/\//.test(url)
  ? new URL(url)
  : new URL(`https://${url}`);

// Good: trust the contract, catch handles actual errors
try {
  return new URL(url).origin;
} catch {
  return null;
}
```

**Ask:** "Can this input actually take the form I'm guarding against? Have I checked?"

## 9. KISS: Simplicity Takes Extra Effort

*"I would have written a shorter letter, but I did not have the time."* — Blaise Pascal

Your first solution works. Now make it simpler. This isn't optional — it's the actual work. Anyone can solve a problem with enough code; the skill is solving it with less. After you get something working, step back and ask: can I remove a layer? Collapse two steps into one? Replace a mechanism with a plain value? The goal isn't cleverness or minimalism — it's the version where the next reader thinks "of course, what else would you do?"

```javascript
// First pass: works, but mechanical
function getDisplayName(user) {
  const parts = []
  if (user.firstName) parts.push(user.firstName)
  if (user.lastName) parts.push(user.lastName)
  if (parts.length === 0) return user.email
  return parts.join(' ')
}

// After thinking it through: same behavior, obvious
const getDisplayName = (user) =>
  [user.firstName, user.lastName].filter(Boolean).join(' ') || user.email
```

This applies at every scale — a function, a module, an architecture. If your solution needs a diagram to explain, keep simplifying until it doesn't.

**Ask:** "This works. Can I make it simpler? What would I remove if I had to?"

## 10. Arrow Functions for Simple Transformations

```typescript
// Bad: Verbose
function executeSymlinkPlan(plan: SymlinkPlan[]): LinkResult[] {
  const results: LinkResult[] = []
  for (const { from, to } of plan) {
    results.push(safeLink(from, to))
  }
  return results
}

// Good: Concise
const executeSymlinkPlan = (plan: SymlinkPlan[]) =>
  plan.map(({ from, to }) => safeLink(from, to))
```

**Note side effects:** Add comment if `.map()` has side effects (creates files, mutates state).

**Minimize boilerplate:**
- Reduce unnecessary ceremony
- Use idiomatic language features (return early, compact conditionals, etc.)
- Don't add comments to obviously simple code

**Prefer directness:**
- Add parameters instead of creating higher-order functions or closures
- Explicit parameters over captured variables
- Avoid over-nesting functions, objects, or data structures
- Clear data flow (inputs → function → outputs)

## Refactoring Checklist

Before code is "done":

1. **Function names read like English?** Should describe exactly what they do
2. **Any copy-pasted code?** Extract to function
3. **Multiple extractType functions?** Replace with `Object.entries(source).map()`
4. **Any function >20 lines?** Break into subfunctions
5. **File >250 lines?** Look for natural module boundaries
6. **Sequential operations with branches?** Consider fluent API
7. **Silently filtering failures?** Make them explicit with error results
8. **Special cases that can be unified?** Handle uniformly when possible
9. **Can it be simpler?** Step back — remove a layer, collapse two steps, replace mechanism with value
10. **Comments explain "why" not "what"?** Code should show what it does
11. **Are implementation details hidden?** Only expose necessary APIs

## Complexity Limits

- Function >25 lines → Extract subfunctions
- File >250 lines → Consider splitting by responsibility
- Nested blocks >2 deep → Extract function

**Self-prompt:** "Do I have extractTypeA/B/C functions? Can I iterate the source instead? Would a fluent API make this read better? Are failures explicit? Does the code read like English? This works — can I make it simpler?"

## Descriptive Names Over Abbreviations

Only abbreviate if universally understood: `i`, `idx`, `err`, `ctx`, `buf`.
Otherwise use full words.

```typescript
// Bad
const c1, c2 = parseArgs(args)
const cfg = getConfig()

// Good
const firstCommit, secondCommit = parseCommits(args)
const config = getConfig()
```

**Exception:** Loop counters (`i`, `j`), error (`err`), buffer (`buf`).

## Configuration Objects Over Positional Parameters

When function takes >3 parameters, use config object.

```typescript
// Bad: Hard to read, rigid order
showList(lines, name, syntax, cursor, keymaps, onSelect)

// Good: Self-documenting, optional fields clear
showList({
  lines,
  name,
  syntax,
  cursor: [4, 0],      // optional
  onSelect: handler,   // optional
})
```

**Benefits:** Named parameters, optional fields obvious, easy to extend.

## Encapsulation of State

Hide storage mechanism. Expose operations, not variables.

```typescript
// Bad: Leaking implementation
if (this.windowId && isValid(this.windowId)) {
  focusWindow(this.windowId)
}

// Good: Operation hides state
panes.focusListWindow()
```

**Inside module:**
```typescript
function focusListWindow() {
  const win = this.windowId  // Internal only
  if (win && isValid(win)) {
    focusWindow(win)
  }
}
```

State storage is implementation detail. Can change without breaking clients.
