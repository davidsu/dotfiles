# TypeScript Type Best Practices

> **Prerequisite**: Also load [javascript.md](javascript.md) — TypeScript shares all JavaScript conventions. This file covers **types only**.

## 1. Prefer Inference Over Explicit Types

Remove return type annotations and variable types when TypeScript can infer them:

```typescript
// Bad
function isSymlink(path: string): boolean { return fs.lstatSync(path).isSymbolicLink() }
const plan: SymlinkPlan[] = files.map(f => ({ from: f, to: transform(f) }))

// Good
function isSymlink(path: string) { return fs.lstatSync(path).isSymbolicLink() }
const plan = files.map(f => ({ from: f, to: transform(f) }))
```

**Type at the source** -- when a function returns a broad type, annotate the variable to help inference flow downstream:

```typescript
// Bad - execSync returns string | Buffer, downstream calls may lose type info
const output = execSync('find . -name "*.txt"', { cwd: rootDir, encoding: 'utf-8' })
return output.trim().split('\n')  // compiler may not know output is string

// Good - annotate the source, inference flows through the chain
const output: string = execSync('find . -name "*.txt"', { cwd: rootDir, encoding: 'utf-8' })
return output.trim().split('\n')  // .trim() knows it's string, .split() returns string[]
```

**Always annotate:** function parameters, public APIs, ambiguous sources (inference fails or infers too broadly)
**Never annotate:** obvious returns (string methods, booleans), intermediate variables, collection operations

## 2. Type Aliases for Complex Signatures Only

Use type aliases when function signatures have 4+ params or complex types (callbacks, generics). Keep simple signatures inline.

```typescript
// Bad - unnecessary aliases
type FilePath = string
function read(path: FilePath) { ... }

// Good - complex signature gets aliases
type FileFilter = (file: string, stats: fs.Stats) => boolean
type FileTransform = (content: string, path: string) => Promise<string>
function process(root: string, filter: FileFilter, transform: FileTransform) { ... }
```

## 3. Accept Nullable Types, Handle Explicitly

Don't filter nulls early - accept `T | null` and handle failures explicitly with error results.

```typescript
// Bad - silently drops failures
const plan = files.map(transformPath).filter(p => p !== null)

// Good - explicit failure tracking
const plan = files.map(f => ({ from: f, to: transformPath(f) })) // to: string | null
const results = plan.map(({ from, to }) => to ? link(from, to) : { from, success: false })
```

## 4. Discriminated Unions for Mutually Exclusive Variants

Use discriminated unions when types have exclusive variants with different required fields.

```typescript
// Bad - optional properties, no enforcement
interface Tool {
  type?: 'brew' | 'native'
  brew_type?: 'formula' | 'cask'  // Should only exist for brew
  install_command?: string         // Should only exist for native
}

// Good - separate types, compile-time safety
type BrewTool = { type: 'brew', brew_type: 'formula' | 'cask', tap?: string }
type NativeTool = { type: 'native', install_command: string, requires?: string[] }
type Tool = BrewTool | NativeTool

// Type narrowing
function install(tool: Tool) {
  if (tool.type === 'native') {
    spawn('bash', ['-c', tool.install_command])  // tool.install_command exists
  } else {
    brew(['install', tool.brew_type])            // tool.brew_type exists
  }
}
```

**Use when:** Variants have different required properties (Result = Success | Error, Response = Loading | Loaded | Failed)

## 5. Only Export What's Used

Export only functions/types actually imported by other modules. Check with `rg "import.*functionName"`.

```typescript
// Bad - over-exporting
export { setupSymlinks, buildSymlinkPlan, safeLink, transformPath }

// Good - only public API (after checking imports with ripgrep)
export { setupSymlinks }
```
