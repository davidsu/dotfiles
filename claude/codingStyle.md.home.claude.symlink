# Coding Style Guide

## Core Principles

- **Keep It Simple (KISS)**
  - Simple code beats clever code
  - Code should be obvious at a glance
  - Avoid over-engineering and premature abstractions

- **Single Responsibility**
  - Each function does one thing
  - Aim for ~20 lines maximum per function
  - Break complex logic into smaller, well-named functions

- **Self-Documenting Code**
  - Use descriptive names for functions and variables
  - Names should express intent clearly
  - Comments organize logic (e.g., "Validation checks", "Error handling")
  - Comments explain "why", not "what" - the code shows what it does
  - Skip comments on self-explanatory code

- **Clear APIs**
  - Hide implementation details
  - Only expose what's necessary
  - Internal helpers should be separate from public functions

- **Structure and Organization**
  - Define functions and configuration logic before return/export statements
  - Keep return/export blocks clean by referencing named functions rather than inline definitions
  - Separate declaration (function definitions) from usage (return/export statements)
  - Extract inline configuration functions into named functions defined above the return/export
  - This improves readability and makes the module's public interface immediately clear

- **Minimize Boilerplate**
  - Reduce unnecessary ceremony
  - Use idiomatic language features (return early, compact conditionals, etc.)
  - Don't add comments to obviously simple code

- **Prefer Directness**
  - Add parameters instead of creating higher-order functions or closures
  - Explicit parameters over captured variables
  - Avoid over-nesting functions, objects, or data structures
  - Clear data flow (inputs → function → outputs)
