---
name: simplify
description: Run simplification pass on working code - eliminate duplication, unify special cases, prefer composition over branching
disable-model-invocation: true
---

# Code Simplification Pass

After getting code working, run mandatory refactoring checklist:

## 1. Duplication Smell

If you have parallel functions doing similar things, there's likely a unified pattern.

**Example**: `transformWithExtension` vs `transformWithoutExtension` → find unified approach

## 2. False Dichotomy Check

Question whether branches represent truly different cases or missing abstraction.

- Ask: "What if I handle both cases uniformly?"
- Look for: Can one case be an empty/identity version of the other?

## 3. Transformation Pipeline Preference

Prefer composing small functions over large conditional branches:

- Break into: extract → transform → combine
- Each step should be a tiny, named function

## 4. Complexity Budget

If file >75 lines or function >25 lines, actively look for simplification.

## 5. Special Case Elimination

Every "special case" handler must justify its existence:

- Try removing the special case first
- Default to uniform handling

## Self-Prompt

Before finishing: "Are there duplicate patterns? Can special cases be unified? Can I use function composition instead of branching?"
