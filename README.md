# 🚀 Dotfiles

> A modern, performance-focused dotfiles configuration optimized exclusively for macOS

<div align="center">

![macOS](https://img.shields.io/badge/macOS-Apple_Silicon-000000?style=flat-square&logo=apple&logoColor=white)
![Neovim](https://img.shields.io/badge/Neovim-57A143?style=flat-square&logo=neovim&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-F15A24?style=flat-square&logo=gnu-bash&logoColor=white)

</div>

---

## ⚡ Quick Start

For a brand-new macOS machine, bootstrap everything with a single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/davidsu/dotfiles/master/installation/bootstrap.sh)"
```

> 💡 **Note:** Ghostty is pre-configured to use JetBrains Mono Nerd Font via `~/.config/ghostty/config` for proper icon display in nvim-tree and terminal applications.

---

## 📋 Prerequisites

- 🍎 **macOS with Apple Silicon** - Designed for M1/M2/M3/M4 chips (Intel support removed)
- 🍺 **Homebrew** - Installation script will auto-install if missing

---

## 🔧 Manual Installation

Clone this repository into `~/.dotfiles` and run the installation script:

```bash
git clone git@github.com:davidsu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./installation/install.ts
```

**The script will:**
1. ✅ Perform pre-flight system checks
2. 📦 Bootstrap `fnm` for Node.js runtime management
3. 🛠️ Install and verify all tools from `installation/tools.yaml`
4. 🔗 Symlink configuration files to their target locations
5. ⚙️ Apply macOS system defaults (disable animations, fast keyboard repeat, etc.)
6. 🎨 Install Neovim plugins via lazy.nvim
7. 🤖 Install Claude Code via native installer (auto-updates enabled)

---

## ✅ Post-install manual steps

After running `./installation/install.ts`, complete these manual steps:

### 1. macOS Privacy & Security permissions

#### Zoom
- Open **System Settings → Privacy & Security**:
  - **Screen Recording**: enable Zoom (needed for screen sharing).
  - **Microphone**: enable Zoom (for audio).
  - **Camera**: enable Zoom (for video).
  - **Accessibility**: enable Zoom if you want remote control / keyboard shortcuts to work properly.
- Start a test meeting and confirm you can share screen + use mic/camera.

#### Karabiner-Elements
- Open **Karabiner-Elements** once so macOS prompts for permissions.
- Then in **System Settings → Privacy & Security**:
  - **Input Monitoring**: enable `Karabiner-Elements`.
  - **Accessibility**: enable `Karabiner-Elements`.
- In Karabiner:
  - Enable the `Karabiner Virtual Keyboard` device in the keyboard settings if prompted.
  - Select your preferred key mappings profile.

#### Rectangle
- Open **Rectangle** once so it requests **Accessibility** permission.
- In **System Settings → Privacy & Security → Accessibility**, enable `Rectangle`.
- Optionally tweak the keyboard shortcuts in Rectangle’s preferences.

### 2. Browser & default apps

#### Brave
- Sign in / enable Brave Sync (if you use it).
- Make Brave the **default browser** via Brave settings.
- **Enable automation** (required for `inspect` command and browser automation):
  - Open Brave → **View** → **Developer** → ✓ **Allow JavaScript from Apple Events**
  - This enables AppleScript to control the browser (used by dotfiles automation scripts)
- Install the **Bitwarden** browser extension in Brave:
  - Open Brave and visit the Chrome Web Store (Brave is Chromium-based): `https://chrome.google.com/webstore/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb`
  - Click **Add to Brave** and confirm.

#### Bitwarden desktop
- Launch the Bitwarden app (installed via Homebrew cask).
- Sign in or create an account.
- (Optional) Enable OS-level autofill / hotkeys in Bitwarden settings.

#### Ghostty
- Open Ghostty and confirm it’s using your config (font, theme, keybindings).
- Optionally:
  - Set Ghostty as your default terminal in any tools that support it.
  - Pin Ghostty to the Dock (the installer clears Dock items).

### 3. Shell / dev environment

- Open a new terminal and verify:
  - `zsh` is the default shell.
  - Starship prompt is active.
  - `fzf`, `zoxide`, `rg`, `fd`, `bat` are on `PATH`.

- Verify **fnm**:
  - Run `fnm --version`.
  - Install Node with `fnm install --lts` or `fnm install <version>`.

- Verify **Neovim**:
  - Run `nvim` once to let it install plugins and LSPs.
  - Open a project and confirm treesitter, LSP, and formatting work.

### 4. Git / GitHub

- Set global Git identity:
  - `git config --global user.name "Your Name"`
  - `git config --global user.email "you@example.com"`

- **Set up SSH key for GitHub** (required for pushing/pulling changes):

  The dotfiles repo is configured to use SSH. Set up your SSH key:

  **Option 1: Step-by-step**
  ```bash
  # 1. Generate an SSH key (if you don't have one)
  ssh-keygen -t ed25519 -C "you@example.com"

  # 2. Add the key to your SSH agent
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519

  # 3. Copy your public key and add it to GitHub
  pbcopy < ~/.ssh/id_ed25519.pub
  # Then go to: https://github.com/settings/keys

  # 4. Test the connection
  ssh -T git@github.com
  ```

  **Option 2: One command**
  ```bash
  ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519 -N "" && \
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519 && \
  pbcopy < ~/.ssh/id_ed25519.pub
  # Then go to: https://github.com/settings/keys and paste
  ```

### 5. Dock & workspace

Because the installer clears the Dock:
- Manually pin apps you care about (Ghostty, Brave, Zoom, Rectangle, etc.).
- Optionally tweak Mission Control / Hot Corners.

---

## 📁 Architecture

### 🗂️ Directory Structure

| Directory | Purpose |
|-----------|---------|
| `installation/` | Bootstrap scripts, `tools.yaml` (packages), `links.ts` (symlinks) |
| `zsh/` | Modular Zsh config (`env.zsh`, `aliases.zsh`, etc.) |
| `DOTconfig.home.symlink/` | Tool configs → `~/.config` |

### 🔗 Symlink Naming Convention

Files use a **self-documenting** naming pattern: `{name}.home[.{path}].symlink[.{extension}]`

**Examples:**
```
DOTzshrc.home.symlink           → ~/.zshrc
CLAUDE.home.DOTclaude.symlink.md → ~/.claude/CLAUDE.md
DOTconfig.home.symlink/          → ~/.config/
```

**Pattern Rules:**
- 📍 `DOT` = literal `.` for hidden files/directories
- 📂 Dots between path components = `/` slashes
- 🎯 Repository organization = ignored (only filename matters!)
- 🤖 `links.ts` parses filenames → destinations (via its internal symlink path transformer)

> 💡 This convention lets you organize by topic in the repo while encoding destination paths in filenames.

---

## 🛠️ Core Tools

### 💻 Development Environment

| Tool | Description |
|------|-------------|
| **Neovim** | 📝 Lua-based editor with fast startup |
| **fnm** | 🔄 Fast Node Manager |
| **ripgrep** | 🔍 Fast search tool with deep integration |

### 🐚 Shell & Terminal

| Tool | Description |
|------|-------------|
| **Zsh** | 🖥️ Modern shell with modular config |
| **Starship** | ⭐ Blazing-fast customizable prompt |
| **Ghostty** | ⚡ GPU-accelerated terminal emulator |

### 🎯 Productivity Tools

**🔎 Fuzzy Finder (fzf)**
- `fag <pattern>` - Search with ripgrep → open in nvim
- `fa` - File finder with bat preview
- `mru` / `1m` - Most recently used files
- `zi` / `jfzf` - Jump to frequent directories
- `bravehistory` - Browse Brave history
- `cb` / `bookmarks` - Browse Brave bookmarks

**⌨️ System Tools**
- 🎹 **Karabiner-Elements** - Vim-style navigation + smart modifiers
- 📐 **Rectangle** - Window management shortcuts

### 🐳 Container & Version Control

| Tool | Description |
|------|-------------|
| **Docker (Colima)** | 📦 Lightweight container runtime |
| **Git** | 🌿 Enhanced config + productivity shortcuts |
| **git-open** | 🔗 Open repo in browser |

---

## ⚙️ Tool Configurations

### 🎨 Prettier (`~/.prettierrc.json`)

```json
{
  "printWidth": 110,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "none"
}
```

### 🔍 Ripgrep (`~/.config/ripgrep/`)

**Config:**
- 👁️ Search hidden files + follow symlinks
- 📏 Max 150 column width
- 📦 Skip files > 10MB

**Ignore patterns (`.rgignore`):**
- 🔒 Lock files (`package-lock.json`, `yarn.lock`, etc.)
- 📦 Minified files (`*.min.js`, `*.map`)
- 📄 Log files (`*.log`)
- ✅ Respects `.gitignore` by default

---

## ⌨️ Keyboard Customization

> 🎹 Powered by **Karabiner-Elements**

### 🧭 Navigation Layer
```
Fn + H/J/K/L → Arrow keys (Vim-style)
Fn + N/M     → Home/End
```

### 🔊 Volume Controls (FC660C)
```
Fn + 9 → Volume Down
Fn + 0 → Volume Up
```

### 🎛️ Smart Modifier Keys
```
Caps Lock → Tap: Escape | Hold: Left Control
Return    → Tap: Return | Hold: Right Control
```

### 🎹 Function Keys
```
F1/F2       → Brightness
F3/F4       → Mission Control/Launchpad
F5/F6       → Keyboard illumination
F7/F8/F9    → Media controls
F10/F11/F12 → Volume
```

---

## 🐚 Shell Customizations

### 🧩 Modularity
- **📂 Organized**: Config split into `zsh/sources/*.zsh` files
- **🔄 Reload**: `reload` or `a` alias to refresh config

### 🧭 Navigation
- `auto_cd` - Type directory name to cd
- `jd` - Jump to `~/.dotfiles`

### 🧪 Power Aliases
- `V` (global) - Pipe command output into a temp file and open it in Neovim
  - Examples: `npm run test V`, `git log --oneline V`

### ⚡ Productivity
- **Global Aliases**: `G` (grep) · `L` (less) · `T` (tail) · `H` (head) · `W` (wc -l)
- **Fuzzy Search**: fzf integration everywhere
- **Smart Completion**: Case-insensitive tab completion

### 🎹 Keybindings
- `Ctrl+P`/`Ctrl+N` + `↑`/`↓` - Prefix-based history search
- `Ctrl+G` - Buffer current line
- `Ctrl+H` - Help for current command

---

## 📝 Logs

Installation logs:
```
~/Library/Logs/dotfiles/install.log
~/Library/Logs/dotfiles/install_errors.log
```

---

## 🤖 Claude Code Setup

> ⚡ **Auto-Updates Enabled**: Claude Code is installed via the native installer, which automatically updates in the background.

### 🔑 API Key Setup (One-time)

Store your Tavily API key in macOS Keychain:

```bash
security add-generic-password -a "$USER" -s "TAVILY_API_KEY" -w "your-api-key" -T /usr/bin/security
```

Get your key at: **https://tavily.com**

### ⚙️ How It Works

1. `zshenv` loads API keys from Keychain → environment variables
2. `.mcp.json` defines MCP servers (no secrets, auto-loaded)
3. `claude/example.claude.json` provides reference configs

### ✅ Verify Setup

```bash
echo $TAVILY_API_KEY  # Should show your key after new shell
```

---

<div align="center">

**Made with ❤️ for macOS**

</div>
