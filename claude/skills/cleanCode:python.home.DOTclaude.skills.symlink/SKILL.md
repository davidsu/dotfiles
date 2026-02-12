---
name: cleanCode:python
description: Python-specific clean code patterns - idiomatic Python, FastAPI conventions, async patterns, and common gotchas
---

# Python Code Simplification

**Core principle:** Python punishes complexity with indentation. Keep it flat, keep it readable.

**Influences:** PEP 8, "Fluent Python" (Luciano Ramalho), The Zen of Python

## Flatten Nesting

4-space indentation makes deep nesting visually painful — by design. The language pushes you toward flat code.

### Extract pure guard helpers to flatten loops

```python
# Bad: if/raise block adds nesting inside a loop
async def _read_stream(response) -> bytes:
    chunks = []
    total = 0
    async for chunk in response.aiter_bytes():
        total += len(chunk)
        if total > MAX_SIZE:
            raise HTTPException(status_code=400, detail="File too large")
        chunks.append(chunk)
    return b"".join(chunks)

# Good: pure guard helper — no side effects, just validates and raises
def _raise_on_size_exceeded(total: int):
    if total > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large")

async def _read_stream(response) -> bytes:
    chunks = []
    total = 0
    async for chunk in response.aiter_bytes():
        total += len(chunk)
        _raise_on_size_exceeded(total)
        chunks.append(chunk)
    return b"".join(chunks)
```

### Combine async context managers (Python 3.10+)

```python
# Bad: nested pyramid
async with httpx.AsyncClient(timeout=30.0) as client:
    async with client.stream("GET", url) as response:
        response.raise_for_status()
        return await _read_stream(response)

# Good: flat
async with (
    httpx.AsyncClient(timeout=30.0) as client,
    client.stream("GET", url) as response,
):
    response.raise_for_status()
    return await _read_stream(response)
```

### Guard clauses over nested ifs

```python
# Bad: nested validation
def process(data):
    if data is not None:
        if data.get("url"):
            if is_valid_url(data["url"]):
                return fetch(data["url"])
    return None

# Good: early returns
def process(data):
    if data is None:
        return None
    url = data.get("url")
    if not url or not is_valid_url(url):
        return None
    return fetch(url)
```

## One-Liner Returns

Skip intermediate variables when the expression is self-explanatory.

```python
# Bad: unnecessary variable
def _extract_filename(url: str) -> str:
    parsed = urlparse(url)
    return parsed.path.split("/")[-1]

# Good: direct
def _extract_filename(url: str) -> str:
    return urlparse(url).path.split("/")[-1]
```

**Keep the variable** when it adds clarity or is reused:

```python
# Good: 'hostname' is clearer than repeating the chain
def _is_internal(url: str) -> bool:
    hostname = urlparse(url).hostname or ""
    return hostname.endswith(".internal.com")
```

## File Layout: Helpers First, Endpoints Last

Structure API files top-to-bottom: imports, constants, helpers, then endpoints.

```python
# 1. Imports
import logging
from fastapi import HTTPException

# 2. Constants
MAX_SIZE = 40 * 1024 * 1024

# 3. Shared helpers
def url_for_file(file_uri: str) -> str: ...

# 4. Private helpers
def _validate_url(url: str): ...
def _extract_filename(url: str) -> str: ...
async def _download_file(url: str) -> bytes: ...

# 5. Endpoints (at the bottom)
@router.get("/{file_uri}")
async def get_file_endpoint(file_uri: str): ...

@router.post("/")
async def upload_file_endpoint(file: UploadFile): ...

@router.post("/reupload")
async def reupload_file_endpoint(url: str = Body(...)): ...
```

Readers see the building blocks first, then the public API that uses them. Matches `custom_integrations/api.py` and other codebase conventions.

## FastAPI Patterns

### Skip one-field Pydantic models — use `Body()` directly

```python
# Bad: ceremony for one field
class ReuploadFileRequest(BaseModel):
    url: str

@router.post("/reupload")
async def reupload(body: ReuploadFileRequest):
    do_something(body.url)

# Good: inline
from fastapi import Body

@router.post("/reupload")
async def reupload(url: str = Body(..., embed=True)):
    do_something(url)
```

**Keep the model** when it has 2+ fields, validation logic, or is reused.

### Request models live next to their endpoint

The codebase convention: define request models in the same file as the route, not in a separate models file. Follow existing patterns.

### Make endpoints read like English

```python
@router.post("/reupload")
async def reupload_file_endpoint(url: str = Body(..., embed=True)):
    _validate_reupload_url(url)
    current_user = User.get_current_user()

    filename = _extract_filename(url)
    content = await _download_file(url)

    user_folder = f"user_{current_user.id}"
    file_uri = await save_file(BytesIO(content), user_folder, filename)
    return {"file_uri": file_uri, "url": url_for_file(file_uri)}
```

Each line is one clear step. Helpers hide the how.

## Comprehensions Over Loops

```python
# Bad: manual accumulation
result = []
for item in items:
    if item.is_active:
        result.append(item.name)

# Good: comprehension
result = [item.name for item in items if item.is_active]
```

**Stop at one level.** Nested comprehensions are unreadable — use a loop or extract a helper.

```python
# Bad: nested comprehension
names = [name for group in groups for item in group.items if item.active for name in item.names]

# Good: extract
def active_names(group):
    return [name for item in group.items if item.active for name in item.names]

names = [name for group in groups for name in active_names(group)]
```

## Python-Specific Gotchas

### `if/raise` is the only way

Python has no inline conditional statements. This is the standard pattern:

```python
if total > MAX_SIZE:
    raise HTTPException(status_code=400, detail="File too large")
```

No shortcut exists. Don't fight it.

### Mutable default arguments

```python
# Bug: shared list across calls
def add_item(item, items=[]):
    items.append(item)
    return items

# Fix: None sentinel
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

### f-strings over concatenation

```python
# Bad
path = "user_" + str(user.id) + "/" + filename
msg = "Failed to fetch %s" % url

# Good
path = f"user_{user.id}/{filename}"
msg = f"Failed to fetch {url}"
```

### Don't catch broad exceptions

```python
# Bad: swallows everything including KeyboardInterrupt
try:
    result = do_something()
except Exception:
    pass

# Good: catch specific errors
try:
    result = do_something()
except (ValueError, KeyError) as e:
    logger.warning(f"Failed: {e}")
    raise HTTPException(status_code=400, detail="Invalid input")
```

## Refactoring Checklist for Python

Before Python code is "done":

1. **Max 2 levels of nesting?** Extract helper or use guard clauses
2. **Async context managers combinable?** Use `async with (a, b):` syntax
3. **One-field Pydantic model?** Replace with `Body(..., embed=True)`
4. **Loop body >3 lines?** Extract to a named helper
5. **Comprehension readable at a glance?** If not, use a loop
6. **`_` prefix on internal helpers?** Don't expose implementation
7. **Endpoint reads like English?** Each line = one clear step
8. **Mutable default args?** Use `None` sentinel
9. **Catching broad exceptions?** Narrow to specific types
10. **Intermediate variables earning their keep?** Drop if the expression is clear

## Complexity Limits

- Function >20 lines -> Extract subfunctions
- File >250 lines -> Consider splitting by responsibility
- Nested blocks >2 deep -> Extract function or guard clause
- Comprehension >1 line -> Consider a loop or helper

**Self-prompt:** "Can I flatten this nesting? Does the function read like a sentence? Is this helper earning its existence or just moving code around? Would a Python developer find this idiomatic?"
