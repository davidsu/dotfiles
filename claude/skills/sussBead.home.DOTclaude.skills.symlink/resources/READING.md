# Bead Reading Protocol

## Parent Traversal — MANDATORY

**Before working on any bead, you MUST read all ancestor epics up to the root.**

1. `bd show <your-bead-id>` — read the bead you're working on
2. If it shows a `PARENT` section, `bd show <parent-id>` — read the parent
3. Repeat until you reach a bead with no parent (the root epic)
4. Read from root down — root epic gives the broadest context, each child narrows scope

This is not optional. Parent epics contain architectural decisions, constraints, and context that child beads assume you know. Skipping them leads to work that contradicts the plan.

## Following Bead References

Bead descriptions contain inline references in this format:

```
beadId#section-slug -> reason this bead is relevant
```

These are **deeplinks** — the `#section-slug` points to a specific `##` or `###` heading inside the target bead. In the Neovim beads viewer, `gd` on a reference opens the bead and jumps to that section.

### When to follow references

- **Do follow** when the summary isn't enough — you need the underlying evidence, exact code locations, or the reasoning behind a conclusion
- **Do follow** when implementing something and the reference points to security concerns, edge cases, or validation details
- **Don't follow** when the synthesizer's summary gives you everything you need
- **Don't follow** every reference exhaustively — use judgment about what's relevant to your current task

### Practical example

You're planning implementation and read a synthesizer bead:

```markdown
### Frontend — 8 REAL Risks

Fresh audit found 8 unguarded locations.

apper-research-fe-audit-v2#frontend-8-real-risks -> found InviteUserModal (missed by first pass)
```

The synthesizer tells you *what* (8 risks). If you need *which files and why*, follow the reference to get the detailed audit.

## Selective Reading with bd-section

Full `bd show <id>` dumps the entire description — often 5-10K+ characters. For large hierarchies (20+ beads), this blows the context window. Use selective loading instead.

The scripts live in the sussBead skill directory. Use full paths:

```bash
BD_SCRIPTS=~/.claude/skills/sussBead/scripts
```

### Summary-only skimming

```bash
# Get just the ## Summary section (default when no slug given)
$BD_SCRIPTS/bd-section <bead-id>

# Explore a full tree with summaries only (~2-5K instead of ~100K)
$BD_SCRIPTS/bd-explore <bead-id>
```

**Always start with `bd-explore`** when entering a bead hierarchy. This gives you the full tree structure with summaries — enough to understand scope and find the specific beads you need.

### Section-level fetch

When a bead reference includes a `#section-slug`:

```
apper-research-fe-audit-v2#frontend-8-real-risks -> found InviteUserModal
```

Instead of loading the full bead, extract just that section:

```bash
$BD_SCRIPTS/bd-section apper-research-fe-audit-v2 frontend-8-real-risks
```

This returns only the `## Frontend — 8 REAL Risks` section content.

### When to use full bd show

Only use `bd show <id>` when you genuinely need the complete description — e.g., implementing from a detailed design bead, or when the summary is insufficient and you need all sections.

### Reading flow

1. `$BD_SCRIPTS/bd-explore <epic-id>` — get the tree with summaries
2. Identify which beads are relevant to your task
3. `$BD_SCRIPTS/bd-section <id> <slug>` — pull specific sections you need
4. `bd show <id>` — only if you need the full description

## Contradiction Escalation — CRITICAL

**If you find contradicting or inconsistent information between beads: STOP IMMEDIATELY.**

1. Do NOT resolve the contradiction yourself
2. Do NOT pick one version over the other
3. Do NOT continue working
4. Escalate to the user/CTO with:
   - Which beads contradict each other (full IDs)
   - What the contradiction is (quote both sides)
   - Which sections are affected
5. Wait for instructions before proceeding

There can be no contradicting data in the bead graph. Contradictions indicate either stale information or a miscommunication that only a human can resolve.

### What counts as a contradiction

- Bead A says "no backend changes needed" but bead B lists backend changes
- Parent epic says "Option B chosen" but child bead implements Option A
- Two sibling beads report different findings about the same code path
- A bead's notes contradict its description (notes may contain updates — check timestamps)

### What is NOT a contradiction

- A child bead adding detail that the parent doesn't mention (that's normal — children narrow scope)
- Notes updating a decision from the description (notes are newer — the latest timestamped entry wins)
- Different beads covering different aspects of the same topic
