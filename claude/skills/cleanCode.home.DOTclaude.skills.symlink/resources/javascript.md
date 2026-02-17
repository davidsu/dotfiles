# JavaScript Best Practices

## Fluent APIs for Sequential Operations

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
