# Reviewing a Teammate's Work

Load this before you sign off on another agent's implementation in a teamup.

## The one rule that matters

**Review against the DECISION, not just the code.** A review is not "is this code clean
and are the tests green?" — it is "does this implementation do what was *decided*?" Clean,
green code that quietly did something *other* than the agreed plan must NOT pass review.

This is the pitfall that has actually bitten: a reviewer read the new code (which was
genuinely clean), saw the tests pass, and signed off — without checking that the core of
the **locked decision** had actually been done. It hadn't; the implementer had taken an
easier path and left the decided work undone. The review approved the deviation.

## Rules

1. **Re-read the plan and locked decisions first.** Before looking at the diff, open the
   task file / decision record and list what was *supposed* to happen. Review the code
   against that list — not against your general sense of "good code."

2. **Read the actual diff for every load-bearing claim. Do not trust the summary.** The
   implementer's prose ("dropped X", "migrated Y to the slot", "removed the old path") is a
   *claim*, not evidence. For each decision-critical point, open the file and confirm it with
   your own eyes. Watch for the trap of *assuming* a change happened: if your own review note
   says "confirm it still works after dropping X," you have assumed X was dropped — go verify
   X was actually dropped.

3. **A deviation goes back to the decision-owner — you do not bless it.** If the
   implementation took a shortcut around a locked decision, your job is to send it back to do
   the decided thing, not to help formalize the shortcut (e.g. by deleting the now-unused
   artifact of the skipped work). Settled decisions are re-opened by their owner, not absorbed
   silently in review.

4. **Surface a deviation AS a deviation, not as a neutral menu.** When you find the code
   diverged from a locked decision, escalate it as "this did not do X, which was decided" —
   not as a balanced A/B options list. A neutral menu invites re-litigation of a settled call
   and quietly pressures the owner toward the easier (deviating) option.

5. **Verify each named invariant has a test that actually covers it.** If the decision listed
   specific behaviors that must keep working, check each one has a real test exercising the new
   path. "All tests green" is not proof — the existing suite may not cover the path the
   implementer changed or skipped.

## In short

You are the guarantee that what shipped is what was decided. Verify against the plan, read the
diff yourself, and hold deviations to the decision.
