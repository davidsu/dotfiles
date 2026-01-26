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

function buildSymlinkPlan(): SymlinkPlan[] {
  return symlinkFiles.map(src => ({ from: src, to: transformPath(src) }))
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

function buildSymlinkPlan() {
  return symlinkFiles.map(src => ({ from: src, to: transformPath(src) }))
}
```

**Why:**
- `.replace()` returns `string` - TypeScript knows this
- `return true/false` is clearly `boolean`
- `.map()` with object literal - TypeScript infers the array type

### Use .map() Instead of Imperative Loops

**Bad:**
```typescript
function buildSymlinkPlan(): SymlinkPlan[] {
  const plan: SymlinkPlan[] = []

  for (const src of symlinkFiles) {
    plan.push({ from: src, to: transformPath(src) })
  }

  return plan
}
```

**Good:**
```typescript
function buildSymlinkPlan() {
  return symlinkFiles.map(src => ({ from: src, to: transformPath(src) }))
}
```

**Why:**
- No need for explicit array type annotation
- No need for return type annotation
- More declarative, less noise
- Compiler infers everything correctly

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
2. **When inference fails** - If compiler infers `any`, you MUST declare explicitly
3. **Public APIs** - Types are documentation for exported functions
4. **Complex inference** - When the inferred type is wrong or unclear

**Example of inference failure:**
```typescript
// Bad: TypeScript infers return type as `any`
function findFiles(rootDir: string) {
  const output = execSync(`find . -name '*.txt'`, { cwd: rootDir, encoding: 'utf-8' })
  return output.trim().split('\n').filter((line) => line.length > 0)
}

// Good: Explicit return type when inference fails
function findFiles(rootDir: string): string[] {
  const output = execSync(`find . -name '*.txt'`, { cwd: rootDir, encoding: 'utf-8' })
  return output.trim().split('\n').filter((line) => line.length > 0)
}
```

**Don't annotate:**
1. **Obvious return types** - String methods, boolean literals, void functions
2. **Variable assignments** - When the value makes the type obvious
3. **Intermediate values** - Let inference flow through transformations

### Benefits

- **Less code** - Fewer type annotations to write and maintain
- **Easier refactoring** - Change implementation, types update automatically
- **Better signal-to-noise** - Annotations that remain are truly meaningful
- **Finds dead code** - Unused interfaces become obvious when you stop annotating

## 2. Type Aliases for Busy Function Signatures

**Rule:** Only use type aliases when the function signature gets "busy" with type noise.

### Simple Signatures - Keep Inline

**Good:**
```typescript
function isSymlink(filePath: string) {
  return fs.lstatSync(filePath).isSymbolicLink()
}

function findSymlinkFiles(rootDir: string): string[] {
  const output = execSync('find . -name "*.txt"', { cwd: rootDir })
  return output.trim().split('\n')
}
```

These are clean - minimal noise, easy to read.

### Busy Signatures - Use Type Alias

**Bad:**
```typescript
function processFiles(
  rootDir: string,
  filter: (file: string, stats: fs.Stats) => boolean,
  transform: (content: string, path: string) => Promise<string>,
  onError: (error: Error, file: string) => void
): Promise<ProcessResult[]> {
  // implementation
}
```

**Good:**
```typescript
type FileFilter = (file: string, stats: fs.Stats) => boolean
type FileTransform = (content: string, path: string) => Promise<string>
type ErrorHandler = (error: Error, file: string) => void
type ProcessFiles = (
  rootDir: string,
  filter: FileFilter,
  transform: FileTransform,
  onError: ErrorHandler
) => Promise<ProcessResult[]>

const processFiles: ProcessFiles = (rootDir, filter, transform, onError) => {
  // implementation
}
```

**Why:** The signature is now scannable - you see the parameter names clearly, and can check the type alias definitions separately if needed.

### When to Use Type Aliases

**Use type aliases when:**
- Function has 4+ parameters
- Parameters have complex types (callbacks, generic types)
- The same signature is used multiple times
- The inline signature makes the function definition hard to scan

**Don't use type aliases when:**
- Function has 1-3 simple parameters
- Types are obvious (string, number, boolean)
- Compiler can infer the return type
- The inline signature is still readable

## References

- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/
- Effective TypeScript by Dan Vanderkam
