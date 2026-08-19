# Color Palette & Brand Style

**This is the single source of truth for all colors and brand-specific styles.** Everything else in the skill is universal.

> House style (replaces the upstream palette; see the VENDORED note in SKILL.md). Reference diagram: apper `suss-tasks/done/new-sandbox-lifecycle/new-sandbox-lifecycle.png` — hand-drawn whiteboard maps on a white canvas, mostly transparent shapes with colored strokes, color-coded flow planes, free-floating labels.

---

## Style Overrides (these win over SKILL.md defaults)

| Property | Value |
|----------|-------|
| Canvas background | `#ffffff` |
| `roughness` | `1` (hand-drawn) — evidence artifacts use `0` |
| `fontFamily` | `1` (Virgil) for all labels/titles; `3` (mono) only inside evidence artifacts |
| Shape fills | `transparent` — meaning lives in the stroke color, not the fill |

## Shape & Flow Colors (Semantic)

Colors encode meaning, not decoration. In multi-plane system diagrams, assign one color per *flow plane* (e.g. data path, control path, GC path) and keep each plane's shapes, arrows, and labels on its color. The primary/hero flow gets `strokeWidth: 4`; everything else `2`.

| Semantic Purpose | Stroke | Notes |
|------------------|--------|-------|
| Default / structure / neutral components | `#1e1e1e` | black, the workhorse |
| Primary data flow (the hero path) | `#2f9e44` | green, strokeWidth 4 |
| Control / secondary flow | `#1971c2` | blue |
| Triggers / periodic / timers | `#f08c00` | orange, often dashed |
| Background jobs / GC / cleanup | `#9c36b5` | purple, often dashed |
| Errors / failure paths / fallbacks | `#e03131` | red, often dashed |
| Annotations, notes, section labels | `#868e96` | gray free-floating text |
| Grouping rooms (dashed boundary rects) | `#adb5bd` | strokeWidth 1, strokeStyle dashed, label inside top-left in gray caps |

## Text Colors (Hierarchy)

| Level | Color | Use For |
|-------|-------|---------|
| Title | `#1e1e1e` | Page title (fontSize ~26) |
| Section/room labels | `#868e96` | UPPERCASE, fontSize ~18 |
| Body/Detail notes | `#868e96` | fontSize 12-13, free-floating under shapes |
| Inside shapes | match the shape's stroke color | |
| Arrow labels | match the arrow's plane color | fontSize 12-13 |

## Evidence Artifact Colors

Code snippets, key/TTL tables, wire payloads, terminal output.

| Artifact | Background | Text |
|----------|-----------|------|
| All evidence blocks | `#1e293b` (roughness 0, rounded) | `#22c55e`, fontFamily 3, fontSize 11-12 |

## Legend

Multi-plane diagrams get a top-right legend: one short line segment per plane color (dashed where the plane's arrows are dashed) + a label in that color, fontSize 13.
