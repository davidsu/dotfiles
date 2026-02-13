# Global Instructions for All Projects

## Auto-Load Skills

### Coding Context

**CRITICAL REQUIREMENT**: Before writing or modifying code, you MUST load `/cleanCode` if you haven't already loaded it in this conversation.

This ensures you follow clean code principles and coding standards automatically.

### Bead Context

**CRITICAL REQUIREMENT**: Before any `bd create`, `bd update`, or when reading beads for context, you MUST load `/sussBead` if you haven't already loaded it in this conversation.

This ensures correct bead writing conventions (ID naming, inline source attribution with `#section-slug`, table alignment) and reading protocol (parent traversal, contradiction escalation).

## NEVER Guess

**CRITICAL**: NEVER guess. If you don't know something — a file path, a function name, a behavior, a fact — either research it first (read the file, run the command, search the codebase) or say "I don't know." Ask the user to clarify if needed. Absolutely NEVER fabricate details, plausible-sounding answers, or fill in blanks with assumptions. Wrong information is worse than no information.

## Ask When Uncertain

If you're uncertain about requirements, ask for clarification BEFORE implementing. If an attempt fails and you still don't understand, STOP and ask - don't loop through guesses.

## Agent answer header

**CRITICAL** ALLWAYS prefix answers with a full line as follows. This makes it easy for the user to parse the conversation

<b>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ANSWER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<</b>
