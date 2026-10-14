# Recipe: a config value for an installed app

- Find the installed version first: `defaults read /Applications/<App>.app/Contents/Info CFBundleShortVersionString`.
- A key or enum copied from a project's `master` source is unverified. Read the **installed** version's
  source (`gh api repos/<owner>/<repo>/contents/<path>?ref=v<X.Y.Z>`) or use the app's own validation.
  iTerm2 3.7.3's `Window Type` enum ends at 18; 19 from master asserted and aborted the app.
- First use of a new profile, rule or plist: a throwaway target, never the window David works in,
  `$G crashes 1` right after.
- Dynamic profiles and plists load silently; a bad value shows up only when the app uses it. Say what
  you installed and when on the channel, so a later crash can be traced to it.

## Stories

- [iterm_crash_2026_10_14.md](../stories/iterm_crash_2026_10_14.md)
