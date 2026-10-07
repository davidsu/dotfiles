# Spawning a cooperating agent

`/suss-teamup spawn [pi|claude|codex] [model] [flavor] [new|subject]` launches another agent in a
new iTerm tab, already joined to a shared channel — for **cross-model pairing**
(claude ⇄ pi ⇄ codex) or, with a **flavor**, a role the peer plays. Agent defaults to
`claude`; channel defaults to a new one.

**Flavors** attach a role + protocol to the spawn. Codified so far: **`handoff`** — hand
a task to a fresh agent and hold its hand to *smart* before it touches code. **Doing a
handoff? Read [handoff.md](resources/handoff.md) first** (durable task file → brief →
verified understanding-check gates the grill → no code before the grill → coordinate the
push) — don't wing it from memory. Planned: `sidecar`, `tester`, `reviewer`. A bare
`spawn` (no flavor) is just a joined peer you then huddle with (SKILL.md → Huddle).

1. **Resolve agent, model + channel.** Agent: `pi`, `claude`, or `codex` (default `claude`).
   Model: a token naming a model (`fable`, `opus`, `sonnet`, `haiku`, or any model id) becomes
   `--model`, so `/suss-teamup spawn fable pair-auth` runs `teamup-spawn claude pair-auth --model fable`.
   Channel: a given `subject` → use it; `new` (or omitted) → pick a short slug
   (e.g. `pair-auth`, `handoff-x`) — avoid names starting with `spawn`.
2. **Join it yourself first**, so you're present when the peer arrives:
   `teamup join {subject} --pwd "$PWD" --doing "spawning a {agent} peer"`.
3. **Spawn the peer:** `scripts/teamup-spawn {claude|pi|codex} {subject} [--as {handle}] [--model {model}] [--role {role}] [--color {color}] [--no-steal]`.
   It opens an iTerm tab in your `$PWD` running the agent, which joins `{subject}`.
   - **Handle**: you assign it (`--as`, default `{subject}.peer{n}`, checked free against the
     roster), and it is final. Make it descriptive (`apper.test.runner`): it is how the user
     finds the session. A claude peer launches with `--name {handle}`; a pi peer gets a leading
     `/banner {handle}`; a codex peer launches bare, then spawn types `/rename {handle}` and the
     join prompt into its idle tab (codex runs no slash commands from argv).
   - **Model**: `--model` goes to the agent's own `--model` flag (`--model fable`).
   - **Color**: `--color` (claude's `/color` palette: red blue green yellow purple orange pink
     cyan), else its `--role`'s color ([known_team_roles.md](known_team_roles.md); no `--role`
     is "anyone else"). A claude peer gets `/color` typed into its tab, retried every second
     until its transcript records it (claude drops keystrokes while it boots); the tab gets
     the same color. A codex peer gets only the tab
     color (`bin/iterm_tab_style`). `--no-steal` (alias `--no-color`) skips coloring.
   - **Failure**: spawn waits until the peer is running and has taken its color. If it never
     does, spawn says `'<handle>' did not come up` and exits 1: look at its tab. With
     `--no-steal` nothing is checked, so check the roster yourself.
4. **Huddle** (SKILL.md → Huddle). For a handoff, post the context the peer needs on the channel
   before it gets going; for pairing, align on who owns what.
