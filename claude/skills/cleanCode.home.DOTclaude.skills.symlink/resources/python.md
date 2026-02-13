# Python Code Simplification

**Core principle:** Python punishes complexity with indentation. Keep it flat, keep it readable.

**For JS/Scala engineers:** This covers Python idioms that differ from what you know.

**Inherited codebase rule:** Existing code may violate these guidelines -- it's legacy. All **new and modified** code must follow these rules. Don't copy patterns from existing code that conflict with what's written here.

## Naming: snake_case World

| Element            | Convention     | Example                                        |
|--------------------|----------------|------------------------------------------------|
| Variables, functions | `snake_case`  | `user_count`, `get_user_by_id()`               |
| Classes            | `PascalCase`   | `UserService`, `RateLimitResult`               |
| Constants          | `UPPER_SNAKE`  | `MAX_RETRIES`, `DEFAULT_TIMEOUT_SECONDS`       |
| Private/internal   | `_prefix`      | `_validate_url()`, `_extract_slug()`           |
| Booleans           | question prefix | `is_active`, `has_permission`, `should_skip`   |
| Settings booleans  | `_enabled` suffix | `audit_logs_enabled`, `redis_compress_enabled` |

**Functions are verb-noun:** `validate_url()`, `build_schema()`, `extract_filename()`, `notify_subscribers()`.

**Classes are domain-specific nouns** -- never bare `Manager`/`Helper`/`Utils`:

```python
# Bad
class Manager: ...
class EmailHelper: ...

# Good -- domain prefix tells you what it manages
class OAuthStateManager: ...
class WorkspaceService: ...
class SendGridFacade: ...
```

## Structured Data: Dataclasses + Enums

### `@dataclass` for internal structured data

Don't pass dicts when fields are known:

```python
# Bad: what keys does this dict have?
result = {"allowed": True, "remaining": 5, "reset_at": 1234}

# Good: self-documenting, IDE autocomplete, type-safe
@dataclass
class RateLimitResult:
    allowed: bool
    remaining: int
    reset_at: int
```

Use **Pydantic `BaseModel`** at API boundaries (request/response), **`@dataclass`** everywhere else.

### `str, Enum` for typed string values

Never compare raw strings for statuses, categories, or types:

```python
# Bad: typo-prone, no autocomplete
if status == "pendding":  # silent bug

# Good: type-safe, discoverable
class AppStage(str, Enum):
    PENDING = "pending"
    READY = "ready"

if status == AppStage.PENDING:  # caught at definition time
```

`str, Enum` allows direct string comparison while providing type safety.

## Constants Over Magic Numbers

```python
# Bad: what do 3 and 6 mean?
if retries > 3:
    abort()
short_id = org_id[:6]

# Good: self-documenting
MAX_RETRIES = 3
SHORT_ID_LENGTH = 6

if retries > MAX_RETRIES:
    abort()
short_id = org_id[:SHORT_ID_LENGTH]
```

Especially for: timeouts, size limits, retry counts, slice indices, threshold values.

## Flatten Nesting

### Extract pure guard helpers

```python
# Bad: if/raise adds nesting inside a loop
async for chunk in response.aiter_bytes():
    total += len(chunk)
    if total > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large")
    chunks.append(chunk)

# Good: guard helper keeps the loop flat
def _check_size_limit(total: int):
    if total > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large")

async for chunk in response.aiter_bytes():
    total += len(chunk)
    _check_size_limit(total)
    chunks.append(chunk)
```

### Combine async context managers (Python 3.10+)

```python
# Bad: nested pyramid
async with httpx.AsyncClient(timeout=30.0) as client:
    async with client.stream("GET", url) as response:
        return await _read_stream(response)

# Good: flat
async with (
    httpx.AsyncClient(timeout=30.0) as client,
    client.stream("GET", url) as response,
):
    return await _read_stream(response)
```

## One-Liner Returns

Skip intermediate variables when the expression is self-explanatory:

```python
# Unnecessary variable
def _extract_filename(url: str) -> str:
    parsed = urlparse(url)
    return parsed.path.split("/")[-1]

# Direct
def _extract_filename(url: str) -> str:
    return urlparse(url).path.split("/")[-1]
```

**Keep the variable** when it adds clarity:

```python
def _is_internal(url: str) -> bool:
    hostname = urlparse(url).hostname or ""
    return hostname.endswith(".internal.com")
```

## File Layout

Structure: imports, constants, shared helpers, private helpers, endpoints.

```python
import logging
from fastapi import HTTPException

MAX_SIZE = 40 * 1024 * 1024

def url_for_file(file_uri: str) -> str: ...

def _validate_url(url: str): ...
def _extract_filename(url: str) -> str: ...
async def _download_file(url: str) -> bytes: ...

@router.post("/reupload")
async def reupload_file_endpoint(url: str = Body(...)): ...
```

Readers see building blocks first, then the public API.

## FastAPI Patterns

### Skip one-field Pydantic models

```python
# Use Body() directly instead of a model for one field
@router.post("/reupload")
async def reupload(url: str = Body(..., embed=True)):
    do_something(url)
```

Keep the model when it has 2+ fields, validation, or is reused.

### Endpoints read like English

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
result = [item.name for item in items if item.is_active]
```

**Stop at one level.** Nested comprehensions are unreadable:

```python
# Bad
names = [name for group in groups for item in group.items if item.active for name in item.names]

# Good: extract helper
def active_names(group):
    return [name for item in group.items if item.active for name in item.names]

names = [name for group in groups for name in active_names(group)]
```

## Walrus Operator `:=`

Assign and test in one expression -- useful for "get then check":

```python
# Without: repeated name
app_context = context.get("app_context")
if app_context:
    log_data["app_id"] = app_context.app_id

# With walrus
if app_context := context.get("app_context"):
    log_data["app_id"] = app_context.app_id
```

Good for `dict.get()`, `re.match()`, `next(..., None)`. Don't nest them.

## Gotchas

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

# Good
path = f"user_{user.id}/{filename}"
```

### Catch specific exceptions

```python
# Bad: swallows everything including KeyboardInterrupt
try:
    result = do_something()
except Exception:
    pass

# Good
try:
    result = do_something()
except (ValueError, KeyError) as e:
    logger.warning(f"Failed: {e}")
    raise HTTPException(status_code=400, detail="Invalid input")
```

## Python Checklist

1. **snake_case everywhere?** No camelCase leaking from JS/Scala
2. **Booleans prefixed?** `is_`/`has_`/`can_`/`should_` (or `_enabled` suffix for settings)
3. **Structured data typed?** `@dataclass` or Pydantic, not bare dicts
4. **String values enumerated?** `str, Enum` not raw string literals
5. **Magic numbers named?** Constants for thresholds, limits, sizes
6. **Async context managers combined?** `async with (a, b):` syntax
7. **One-field Pydantic model?** Replace with `Body(..., embed=True)`
8. **Loop body >3 lines?** Extract to a named helper
9. **Comprehension readable at a glance?** If not, use a loop
10. **`_` prefix on internal helpers?** Don't expose implementation
11. **Endpoint reads like English?** Each line = one clear step
12. **Intermediate variables earning their keep?** Drop if the expression is clear
13. **Mutable default args?** Use `None` sentinel
14. **Catching broad exceptions?** Narrow to specific types

## Complexity Limits

- Comprehension >1 line -> Consider a loop or helper

**Self-prompt:** "Does the function read like a sentence? Is this helper earning its existence or just moving code around? Would a Python developer find this idiomatic?"
