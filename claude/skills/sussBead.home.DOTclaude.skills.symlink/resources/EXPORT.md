# Bead Export — Markdown with Working Links

Export a bead and all its referenced beads as a directory of `.md` files with proper markdown links.

## Invocation

```
/sussBead export <bead-id>
```

## Output

```
/tmp/beads-export/<bead-id>/
  <bead-id>.md          # root bead
  <referenced-bead>.md  # each referenced bead
  ...
```

## Algorithm

### 1. Collect All Bead IDs

Starting from the root bead, recursively collect every bead ID that needs exporting:

1. `bd show <root-id>` — get root bead content
2. If root is an **epic**, also fetch all children: `bd list --json --parent <root-id>` — add their IDs
3. Scan content for bead references (patterns below) — add referenced IDs
4. For each newly added ID, fetch its content and repeat step 3
5. Stop when no new IDs are discovered (visited set)

**Reference patterns to scan for** (same as viewer.lua's `parseBeadRef`):

```
beadId#section-slug -> reason     # most common
beadId#section-slug               # without reason
beadId:lineNumber                 # line reference (rare in exports)
```

Bead IDs match: `%.?[%w][%w%-%.]+` (optional dot prefix, alphanumeric/hyphens/dots).

### 2. Export Each Bead

For each collected bead ID:

```bash
bd show <id> > /tmp/beads-export/<root-id>/<id>.md
```

### 3. Convert Deeplinks to Markdown Links

In every exported `.md` file, convert bare deeplinks to markdown links:

**Pattern 1**: `beadId#section-slug -> reason`

```
# Before:
apper-research-ssrf-ai-scraping#path-1-agents-real-ssrf -> unprotected aiohttp fetch

# After:
[apper-research-ssrf-ai-scraping#path-1-agents-real-ssrf](./apper-research-ssrf-ai-scraping.md#path-1-agents-real-ssrf) -> unprotected aiohttp fetch
```

**Pattern 2**: `beadId#section-slug` (no reason)

```
# Before:
apper-research-ssrf-ai-scraping#path-1-agents-real-ssrf

# After:
[apper-research-ssrf-ai-scraping#path-1-agents-real-ssrf](./apper-research-ssrf-ai-scraping.md#path-1-agents-real-ssrf)
```

**Conversion rule**: `ID#SLUG` becomes `[ID#SLUG](./ID.md#SLUG)`

Only convert references whose bead ID exists in the export set. Leave unknown references as plain text.

### 4. Verify

After export, list the directory contents and print a summary:

```
Exported 12 beads to /tmp/beads-export/apper-research-ssrf/
```

## Implementation Notes

- Use `sed` or string replacement in a loop — no external tools needed
- The `-> reason` suffix stays outside the link: `[ID#SLUG](./ID.md#SLUG) -> reason`
- Don't convert references already inside markdown links `[...](...)` — avoid double-wrapping
- File references like `backend/app/models.py:42` are NOT bead references — they contain `/` which bead IDs never do. Don't touch them.
- The `bd show` header lines (status, owner, dates) are fine to include — they provide useful context in exported files
