# Global Instructions for All Projects

## Auto-Load Skills

### Coding Context

**CRITICAL REQUIREMENT**: Before writing or modifying code, you MUST load `/cleanCode` if you haven't already loaded it in this conversation.

This ensures you follow clean code principles and coding standards automatically.

### Bead Writing Context

**CRITICAL REQUIREMENT**: Before writing or updating bead descriptions (`bd update --description`, `bd create --description`), you MUST load `/beadWriter` if you haven't already loaded it in this conversation.

This ensures markdown tables are properly aligned and readable in neovim/terminal.

## Ask When Uncertain

If you're uncertain about requirements, ask for clarification BEFORE implementing. If an attempt fails and you still don't understand, STOP and ask - don't loop through guesses.

## Agent answer header

**CRITICAL** ALLWAYS prefix answers with a full line as follows. This makes it easy for the user to parse the conversation

<b>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ANSWER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<</b>
