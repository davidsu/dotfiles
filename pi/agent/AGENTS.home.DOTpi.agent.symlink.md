# Global Agent Instructions

## Search Rules

- NEVER use `grep` via bash. Always use the built-in `grep` tool, which uses ripgrep under the hood.
- If you must search via bash, use `rg` (ripgrep), never `grep`.

## Tools

- jq is available in the filesystem. prefer using jq to python for working with json
