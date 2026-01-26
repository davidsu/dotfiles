---
name: cleanTypes
description: TypeScript type best practices - proper typing patterns, avoiding type complexity, meaningful type annotations
---

# TypeScript Type Best Practices

## 1. Implicit is Better Than Explicit

**Rule:** If TypeScript can infer the type, don't annotate it.

TypeScript has powerful type inference. Let the compiler do the work.

### Remove Return Type Annotations

**Bad:**
```typescript
const extractExtension = (filename: string): string =>
  filename.replace(/.*symlink/, '')

function isSymlink(filePath: string): boolean {
  try {
    return fs.lstatSync(filePath).isSymbolicLink()
  } catch {
    return false
  }
}

const createLogFunction = (level: LogLevel) => (msg: string): void => {
  execSync(`source "${SCRIPT}" && log_${level} '${msg}'`)
}
```

**Good:**
```typescript
const extractExtension = (filename: string) =>
  filename.replace(/.*symlink/, '')

function isSymlink(filePath: string) {
  try {
    return fs.lstatSync(filePath).isSymbolicLink()
  } catch {
    return false
  }
}

const createLogFunction = (level: LogLevel) => (msg: string) => {
  execSync(`source "${SCRIPT}" && log_${level} '${msg}'`)
}
```

**Why:**
- `.replace()` returns `string` - TypeScript knows this
- `return true/false` is clearly `boolean`
- `execSync()` doesn't return a useful value - TypeScript infers `void`

### Remove Variable Type Annotations

**Bad:**
```typescript
interface Logger {
  info: (msg: string) => void
  success: (msg: string) => void
  warn: (msg: string) => void
  error: (msg: string) => void
}

const log: Logger = {
  info: createLogFunction('info'),
  success: createLogFunction('success'),
  warn: createLogFunction('warn'),
  error: createLogFunction('error')
}
```

**Good:**
```typescript
const log = {
  info: createLogFunction('info'),
  success: createLogFunction('success'),
  warn: createLogFunction('warn'),
  error: createLogFunction('error')
}
```

**Why:**
- TypeScript infers the shape from the object literal
- If you remove the annotation and the interface becomes unused, delete it
- Less noise, same type safety

### When to Keep Type Annotations

**Do annotate:**
1. **Function parameters** - Always annotate (TypeScript can't infer these)
2. **Public APIs** - Types are documentation for exported functions
3. **Complex inference** - When the inferred type is wrong or unclear

**Don't annotate:**
1. **Obvious return types** - String methods, boolean literals, void functions
2. **Variable assignments** - When the value makes the type obvious
3. **Intermediate values** - Let inference flow through transformations

### Benefits

- **Less code** - Fewer type annotations to write and maintain
- **Easier refactoring** - Change implementation, types update automatically
- **Better signal-to-noise** - Annotations that remain are truly meaningful
- **Finds dead code** - Unused interfaces become obvious when you stop annotating

## References

- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/
- Effective TypeScript by Dan Vanderkam
