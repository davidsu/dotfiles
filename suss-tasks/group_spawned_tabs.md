open
# Visually group spawner + peer tabs on `/suss-teamup spawn`

## Summary

When `/suss-teamup spawn` launches a peer, make the spawner's tab and the new
peer's tab look like a matched pair: a shared name prefix/middle with a per-tab
handle suffix, and the **same** tab color. Deferred because reading a tab's
*existing* color via macOS accessibility is unverified and looks hard.

## Requirements (from user)

### 1. Tab name: `{subject}:{tabname}:{teammemberidentifier}`

- **Prefix** = `{subject}` (the channel). Both tabs get the **same** prefix.
  If the current (spawner) tab name doesn't already carry a `{subject}` prefix,
  create one.
- **Middle** = `{tabname}` — shared base label, same on both tabs.
- **Suffix** = the handle each agent uses *in the channel* (per-tab, differs).

### 2. Tab color: same for both

- If the current (spawner) tab **already has a color**, reuse it for the new tab.
- If it has **no color**, pick a random one and apply the **same** color to both.

## Design notes

- **Peer handle is self-chosen.** The peer picks its own channel handle after it
  boots (e.g. `dotfiles-pi`), so the spawner can't pre-name the peer's tab with
  it. The peer must rename **its own** tab after joining — pass `{subject}` +
  `{tabname}` + the chosen color to it via the init prompt, and have it run the
  rename + color on its own tab once it knows its handle.
- **Setting** a tab name is easy (`set_tab_title` perform action). **Setting** a
  color works via the existing swatch-press flow (poll the lazily-realized swatch
  grid at menu item 8, `AXPress` the swatch whose `help` matches).

## ⚠️ Blocker — reading a tab's current color

Requirement 2's "reuse the existing color if present" needs to **read** the
spawner tab's applied color. It is unclear Ghostty exposes this at all:

- A probe enumerating every attribute of the selected tab's `AXRadioButton`, and
  every attribute of each color-swatch `AXButton` while the menu was open
  (looking for a selected/checkmark marker), returned **nothing useful**.
- Next angles to try: `AXMenuItemMarkChar` / `AXSelected` on the applied swatch;
  any color attribute on the tab button not surfaced by the probe; or accept that
  the color is not AX-readable.
- **Fallback if unreadable:** always *choose* a color at spawn time and apply it
  to both tabs (drop the "reuse the tab's existing color" clause), or track tab
  colors out-of-band (e.g. a small state file keyed by tab id).

## Relevant files

- [teamup-spawn](/claude/skills/suss-teamup.ln/scripts/teamup-spawn) — spawns the peer
- [SKILL.md](/claude/skills/suss-teamup.ln/SKILL.md?plain=1) — `## Spawn a cooperating agent`
- [ghostty_spawn](/bin/ghostty_spawn) — opens a tab running a command
- [ghostty_tab](/bin/ghostty_tab) — rename + color the current tab (swatch-press flow to copy)

## Notes

- 2026-06-25: Deferred mid-investigation so the user could work. The probe script
  lived at `scratchpad/probe_color.scpt` (session scratchpad, ephemeral).
- The swatch-press color flow already proven: button 1 of the grid is "None";
  buttons 2..end are the colors (Blue Purple Pink Red Orange Yellow Green Teal Graphite).

---
**Created by**: claude-code-session (2026-06-25)
