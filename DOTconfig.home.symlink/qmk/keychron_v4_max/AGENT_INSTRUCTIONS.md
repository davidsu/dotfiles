# Agent Instructions - Keychron V4 Max QMK Configuration

## Project Overview

This project migrates the user's keyboard customizations from Karabiner-Elements to QMK firmware for a Keychron V4 Max 60% keyboard. The user's workplace does not allow Karabiner, so all customizations must be implemented directly in the keyboard firmware.

## User Requirements

The user had two primary configuration sources:
1. **Karabiner config**: `/Users/thistooshallpass/.config/karabiner/karabiner.json`
2. **GK6X config**: `/Users/thistooshallpass/Developer/GK6X/Build/UserData/655491117.txt`

### Critical Features Implemented

#### 1. Dual-Function Keys (Tap vs Hold)
- **Caps Lock**: Escape when tapped, Left Ctrl when held
- **Enter**: Enter when tapped, Right Ctrl when held

#### 2. Physical Key Remaps
- **Escape key** (upper left corner): Remapped to Backtick/Tilde [`~]
- **Left Ctrl** (lower left): Activates VIM layer when held

#### 3. Layer Switching

**IMPORTANT NOTE FOR FUTURE REFACTORING:**
Current implementation has multiple ways to switch layers (listed below). This works well but could be simplified in the future. The redundancy exists because:
- We wanted to keep Left Ctrl as momentary VIM layer activation
- We also wanted Ctrl+Q/W/E/R for layer switching
- Solution: Q/W/E/R switch layers directly in VIM/NUMPAD/BLUETOOTH (no Ctrl needed)
- This makes Right Ctrl+Q/W/E/R redundant except in BASE layer
Consider revisiting to make this cleaner/more consistent.

**Current Layer Switching Methods:**

**From BASE layer:**
- **Hold Left Ctrl** (bottom left) → Temporarily activate VIM layer (release to return)
- **Ctrl + `` ` ``** (physical Escape key) → Switch to Bluetooth layer permanently
- **Ctrl + Q/W** → Switch to Base layer permanently
- **Ctrl + E** → Switch to VIM layer permanently
- **Ctrl + R** → Switch to Numpad layer permanently
- Works with both physical Left Ctrl and Right Ctrl
- **Visual indicator:** `` ` ``, Q/W/E/R light up RED when physical Ctrl is pressed
- **Does NOT work** with Caps Lock or Enter (even though they act as Ctrl when held)

**From VIM layer:**
- **Q or W** → Switch to Base layer (no Ctrl needed)
- **E** → Stay in VIM layer
- **R** → Switch to Numpad layer (no Ctrl needed)
- **S** → Switch to Numpad layer (legacy, same as R)
- **D** → Switch to Base layer (legacy, same as Q/W)

**From NUMPAD layer:**
- **Q or W** → Switch to Base layer (no Ctrl needed)
- **E** → Switch to VIM layer (no Ctrl needed)
- **R** → Stay in Numpad layer
- **S** → Switch to VIM layer (legacy, same as E)
- **D** → Switch to Base layer (legacy, same as Q/W)

**From BLUETOOTH layer:**
- **Q or W** → Switch to Base layer (no Ctrl needed)
- **E** → Switch to VIM layer (no Ctrl needed)
- **R** → Switch to Numpad layer (no Ctrl needed)

**RGB Control:**
- **Ctrl + \\** → Toggle base layer RGB on/off (works with physical Left or Right Ctrl)

#### 4. VIM Layer (Layer 2)
Can be activated by:
- Right Ctrl + E (permanent switch)
- Hold Left Ctrl (momentary activation)

**Navigation:**
- H → Left Arrow
- J → Down Arrow
- K → Up Arrow
- L → Right Arrow
- M → Home
- Comma (,) → End
- U → Page Up
- I → Page Down

**Volume Controls:**
- 8 → Mute
- 9 → Volume Down
- 0 → Volume Up

**Editing:**
- Backspace → Forward Delete

**Layer Switching:**
- S → Switch to Numpad layer (Layer 3)
- D → Return to Base layer
- Shift → Still functions as Shift

**Disabled Keys:**
Letters A, B, C, E, F, G, N, O, P, Q, R, T, V, W, X, Y, Z and numbers 1-7 are disabled in this layer (return KC_NO).

#### 4. Numpad Layer (Layer 3)
Accessible by pressing S while in VIM layer or Right Ctrl + R:

**Number Mappings (using regular digits, not numpad keycodes):**
```
Top row: 1 2 3 4 5 6 7 8 9 0 → 1 2 3 4 5 6 7 8 9 0
Letters:  U I O → 7 8 9
         J K L → 4 5 6
       M , . N → 1 2 3 0
```

**Special Characters (lit in RED):**
```
; → , (comma)
/ → . (period)
\ → / (division)
```

**Mathematical Operators (natural Shift positions):**
- ! (Shift+1) → ! (factorial)
- Shift+5 → % (modulo)
- Shift+6 → ^ (power)
- Shift+8 → * (multiply)
- - → - (minus)
- Shift+- → _ (underscore)
- = → = (equals)
- Shift+= → + (plus)
- Shift+, → < (less than)
- Shift+. → > (greater than)

**Layer Switching:**
- S → Switch to VIM layer
- D → Return to Base layer

#### 5. Bluetooth Layer (Layer 3)
Accessible by pressing **Ctrl + `` ` ``** (physical Escape key/Grave key):

**Purpose:**
This layer was added to enable Bluetooth device pairing while keeping all keys in their stock positions, particularly the Fn keys that are remapped to arrows in the BASE layer.

**Bluetooth Pairing:**
- **Fn + Q** (hold 4 seconds) → Pair to Bluetooth device slot 1
- **Fn + W** (hold 4 seconds) → Pair to Bluetooth device slot 2
- **Fn + E** (hold 4 seconds) → Pair to Bluetooth device slot 3
- **Fn + Q/W/E** (tap) → Switch between already paired devices

**Important Notes:**
- Pairing can be done while USB cable is connected
- To actually USE Bluetooth connection:
  1. Flip the physical mode switch on keyboard to BT
  2. Unplug the USB cable
  3. Keyboard will connect to the last active device
- The Fn keys on the bottom row are set to `KC_TRNS` (transparent) to allow pass-through to Keychron's proprietary firmware layer

**Bottom Row Layout (Stock):**
Unlike BASE layer where Fn keys are remapped to arrows, this layer preserves:
- Left Ctrl, Left Alt, Left Cmd, Space, Right Cmd, Fn1, Right Ctrl

**RGB Lighting:**
- Q, W, E → Cyan (shows pairing keys)
- Fn1 → Cyan (function keys for pairing)
- All other keys → Off

**Layer Switching:**
- Q or W → Switch to Base layer (no Ctrl needed)
- E → Switch to VIM layer (no Ctrl needed)
- R → Switch to Numpad layer (no Ctrl needed)

#### 6. Right Side Arrow Keys
Keys to the right of spacebar (bottom row):
- Right Cmd → Left Arrow
- Fn1 → Down Arrow
- Fn2 → Right Arrow
- Right Ctrl → Stays Ctrl, but **Right Ctrl + /** → Up Arrow

#### 7. RGB Lighting Layer Indication

**Base Layer:** Solid white (can be toggled off with Ctrl+\\)

**VIM Layer:** Per-key colors (from GK6X vimLike.le):
- S & D (layer switching): Dark blue
- 8, 9, 0 (volume): White
- U & I (Page Up/Down): Orange
- M & Comma (Home/End): Green
- Backspace (Forward Delete): Red
- H, J, K, L (arrows): Purple
- All other keys: Off

**Numpad Layer:** Per-key colors (from GK6X numpad.le):
- Numbers 1-9 (U, I, O, J, K, L, M, Comma, Period): Purple
- Number 0 (N): Green
- Semicolon & Slash (numpad comma/period): Red
- S & D (layer switching): Dark blue
- All other keys: Off

**Bluetooth Layer:** Per-key colors:
- Q, W, E (pairing keys): Cyan
- Fn1 (function keys): Cyan
- All other keys: Off

**All Layers (when Ctrl pressed):**
- `` ` `` (Escape/Grave key): Red (Ctrl+`` ` ``→Bluetooth layer)
- Q, W (Base layer): Red
- E (VIM layer): Red
- R (Numpad layer): Red

## NOT Implemented (from Karabiner)

The following Karabiner feature was NOT implemented due to QMK limitations:

**Left Ctrl + W Scroll Layer**: This created a temporary scroll mode in Karabiner where Left Ctrl + W, then J/K/U/D/H/L would perform mouse scrolling. QMK does not support this type of sequential key activation for mouse scrolling as elegantly as Karabiner.

## File Structure

### Configuration Files Location: `~/.config/qmk/keychron_v4_max/`
- `keymap.c` - Main keymap configuration with 4 layers (BASE, VIM, NUMPAD, BLUETOOTH)
- `config.h` - Timing and behavior settings
- `rules.mk` - Build rules and feature flags
- `README.md` - Setup and usage instructions
- `QUICK_REFERENCE.md` - Quick reference cheat sheet
- `AGENT_INSTRUCTIONS.md` - This file
- `v4_max_ansi_v1.1.1_2507021559.bin` - Stock firmware backup (103,892 bytes)
- `keychron_v4_max_ansi_custom.bin` - Compiled custom firmware (94,680 bytes)

### QMK Firmware Locations:

**~/qmk_firmware/** (Standard QMK - NOT USED)
- Contains standard QMK repository
- Has `keychron/v4` but NOT `v4_max`
- ⚠️ DO NOT USE FOR V4 MAX

**~/keychron_qmk_firmware/** (Keychron's Fork - REQUIRED)
- Keychron's QMK fork with wireless support
- Branch: `wireless_playground`
- Custom keymap location: `keyboards/keychron/v4_max/ansi/keymaps/custom/`
- Compiled firmware: `keychron_v4_max_ansi_custom.bin`

## Current Status

✅ **WORKING FEATURES:**
- Tap Caps Lock → Escape
- Hold Caps Lock → Ctrl
- Tap Enter → Enter
- Hold Enter → Right Ctrl
- Physical Escape key → Backtick/Tilde
- Hold Left Ctrl → Activates VIM layer
- Ctrl + `` ` `` → Switches to Bluetooth layer
- VIM layer navigation: H/J/K/L → Arrows
- VIM layer: M/Comma → Home/End
- VIM layer: U/I → Page Up/Down
- VIM layer: 8/9/0 → Volume controls
- VIM layer: Backspace → Forward Delete
- VIM layer: S → Switch to Numpad, D → Return to Base
- Numpad layer works (numbers on UIOJKLM,.)
- Bluetooth layer works (Fn+Q/W/E for pairing)
- Bluetooth layer RGB: Q/W/E and Fn1 in cyan
- Right side arrows work (Right Cmd/Fn1/Fn2)
- Right Ctrl + / → Up arrow
- Layer switching indicators: `` ` ``/Q/W/E/R glow red when Ctrl pressed

✅ **RGB LIGHTING FIXED (2026-02-01):**
- Per-key RGB lighting now working correctly
  1. Base layer returns to white properly
  2. LED indices corrected (H, J, K, L, S, D, M, Comma all light up correct keys)
- See "RGB Lighting Issues" section below for technical details

**All Features Now Working (2026-02-01 final):**
- All numbers 0-9 work on top row in numpad layer ✓
- All numbers work on letter keys (UIOJKLM,.N) ✓
- Mathematical operators: =, +, -, _, !, ^, % all working ✓
- Division: \ → / working and lit in red ✓
- ; → , (comma) working ✓
- / → . (period) working ✓
- Both Left Ctrl and Right Ctrl + Q/W/E/R for layer switching ✓
- Q/W/E/R light up RED when physical Ctrl pressed (visual indicator) ✓
- Ctrl + \ toggles base layer RGB on/off ✓
- P key disabled in numpad layer ✓

✅ **COMPILATION SETUP COMPLETED:**
- QMK toolchain installed via pipx (not Homebrew due to Python path issues)
- Build dependencies installed (avr-gcc@8, arm-none-eabi-gcc@8, etc.)
- Standard QMK repository cloned to `~/qmk_firmware` (not used for V4 Max)
- Keychron's QMK fork cloned to `~/keychron_qmk_firmware` (wireless_playground branch)
- Stock V4 Max firmware downloaded and tested: `v4_max_ansi_v1.1.1_2507021559.bin` (103,892 bytes)
- Keyboard hardware verified working with stock firmware
- Custom keymap successfully compiled for V4 Max: `keychron_v4_max_ansi_custom.bin` (94,876 bytes latest)
- Custom firmware flashed to keyboard multiple times

❌ **ISSUES DISCOVERED & RESOLVED:**
- ✅ Wrong firmware initially used (V4 vs V4 Max) - caused keyboard brick, recovered with stock firmware
- ✅ V4 Max requires Keychron's fork (github.com/Keychron/qmk_firmware), not standard QMK
- ✅ Must use `wireless_playground` branch for V4 Max support
- ✅ Layout macro is `LAYOUT_ansi_61` not `LAYOUT_60_ansi`
- ✅ Must disable `RGBLIGHT_ENABLE` (V4 Max uses RGB_MATRIX only)
- ✅ Must remove `IGNORE_MOD_TAP_INTERRUPT` (now default behavior)
- ✅ Must disable `LTO_ENABLE` to avoid type mismatch error in Keychron's wireless code
- ✅ Escape key method for bootloader works (unplug → hold Esc → plug in)

⏸️ **PENDING:**
- Test all features from testing checklist (especially RGB colors)
- Verify H/J/K/L and S/D light up correctly in VIM layer
- Verify base layer returns to white when exiting VIM layer

## RGB Lighting Issues

### Fix #2: LED Index Mapping and Base Layer Clearing (2026-02-01)

**Root Cause Found:**

Analyzed `~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/ansi.c` and found the `g_led_config` structure (lines 98-123) which maps keyboard matrix positions to LED indices.

**LED Matrix Mapping (from ansi.c lines 100-105):**
```c
{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13 },  // Row 0
{ 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 },  // Row 1
{ 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, __, 40 },  // Row 2
{ 41, __, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, __, 52 },  // Row 3
{ 53, 54, 55, __, __, __, 56, __, __, __, 57, 58, 59, 60 }   // Row 4
```

**Correct LED Indices:**
- Row 2: Caps=28, **A=29**, **S=30**, **D=31**, F=32, **G=33**, **H=34**, **J=35**, **K=36**, **L=37**, ;=38, '=39, Enter=40
- Row 3: LShift=41, Z=42, X=43, C=44, V=45, B=46, N=47, **M=48**, **Comma=49**, .=50, /=51, RShift=52

**Incorrect Indices in Original Code:**
- S: was 29, should be **30** (+1)
- D: was 30, should be **31** (+1)
- H: was 33, should be **34** (+1)
- J: was 34, should be **35** (+1)
- K: was 35, should be **36** (+1)
- L: was 36, should be **37** (+1)
- M: was 47, should be **48** (+1)
- Comma: was 48, should be **49** (+1)

**Base Layer Not Clearing Issue:**

The `rgb_matrix_indicators_advanced_user()` function was using `rgb_matrix_mode_noeeprom()` and `rgb_matrix_sethsv_noeeprom()` for base/numpad layers, but this doesn't clear the per-key colors set by `rgb_matrix_set_color()` in VIM layer.

**Solution:** Explicitly set all LED colors using loops in ALL three layers:
- BASE layer: Loop through all LEDs and set to RGB(255, 255, 255) - white
- NUMPAD layer: Loop through all LEDs and set to RGB(0, 255, 0) - green
- VIM layer: Already doing this (sets all to black, then specific keys to colors)

**Implementation Changes:**
1. Fixed all LED indices by adding +1 to affected keys
2. Changed base/numpad layer handling to use explicit LED color loops instead of mode/HSV functions
3. All three layers now use consistent approach of setting individual LED colors

**Code Location:**
- File: `~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/keymap.c`
- Function: `rgb_matrix_indicators_advanced_user()`
- Lines: ~116-162

---

### Attempted Fix #1: Per-Key RGB for VIM Layer (SUPERSEDED)

**Goal:** Implement per-key RGB colors matching GK6X vimLike.le profile instead of solid blue.

**GK6X VIM Layer Colors (from vimLike.le):**
- S & D (layer switching): Dark blue `0x020020`
- 8, 9, 0 (volume): White `0xFFFFFF`
- U & I (Page Up/Down): Orange `0xFFA500`
- M & Comma (Home/End): Green `0x00FF00`
- Backspace (Forward Delete): Red `0xFF0000`
- H, J, K, L (arrows): Purple `0x800080`
- All other keys: Off/dark

**Implementation:** Used `rgb_matrix_indicators_advanced_user()` in keymap.c to set individual LED colors.

**Problems Found:**
1. **Base layer not white**: VIM layer colors persist when returning to base layer
2. **LED indices off by one to the left**: All keys shifted one position left

**Status:** ✅ FIXED in Fix #2 above

## Technical Details

### QMK Installation Method
- **DO NOT** use `brew install qmk` - it has Python interpreter path issues
- **USE** `pipx install qmk` instead
- QMK CLI version: 1.2.0
- QMK firmware version: 0.31.9

### Build Toolchain
Installed via Homebrew but keg-only (not in default PATH):
```bash
/opt/homebrew/opt/avr-gcc@8/bin
/opt/homebrew/opt/arm-none-eabi-gcc@8/bin
/opt/homebrew/opt/arm-none-eabi-binutils/bin
/opt/homebrew/opt/avr-binutils/bin
```

**IMPORTANT:** Do NOT add these paths to `~/.zshrc` permanently. They should only be exported when running qmk compile commands:
```bash
# Only use when compiling - do not add to shell config!
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:$PATH"
export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"
export PATH="/opt/homebrew/opt/arm-none-eabi-binutils/bin:$PATH"
export PATH="/opt/homebrew/opt/avr-binutils/bin:$PATH"
```

### Build Toolchain Installation (From Scratch)

**⚠️ CRITICAL: Use the osx-cross tap, NOT homebrew/core formulas!**

The standard `brew install arm-none-eabi-gcc` (homebrew/core) is **missing newlib** and will fail with:
```
fatal error: stdint.h: No such file or directory
```

**Correct installation:**
```bash
# 1. Install QMK CLI via pipx (NOT brew install qmk - has Python path issues)
brew install pipx
pipx ensurepath
pipx install qmk

# 2. Tap the osx-cross repositories (provides @8 versions with newlib)
brew tap osx-cross/arm
brew tap osx-cross/avr

# 3. Install the ARM toolchain (for V4 Max - ARM Cortex-M4)
#    If you have homebrew/core arm-none-eabi-* installed, uninstall first:
brew uninstall arm-none-eabi-binutils arm-none-eabi-gcc 2>/dev/null || true
brew install osx-cross/arm/arm-none-eabi-gcc@8

# 4. Install AVR toolchain (for other keyboards, optional for V4 Max)
brew install osx-cross/avr/avr-gcc@8

# 5. Clone Keychron's QMK fork (if not already done)
cd ~
git clone https://github.com/Keychron/qmk_firmware.git keychron_qmk_firmware
cd keychron_qmk_firmware
git checkout wireless_playground
git submodule update --init --recursive

# 6. Install Python dependencies for Keychron's fork
~/.local/pipx/venvs/qmk/bin/python -m pip install -r ~/keychron_qmk_firmware/requirements.txt
```

**Why osx-cross/arm/arm-none-eabi-gcc@8?**
- The QMK formula (`qmk/qmk/qmk`) depends on `osx-cross/arm/arm-none-eabi-gcc@8`
- This version includes newlib (C standard library for embedded)
- The homebrew/core `arm-none-eabi-gcc` is a bare compiler without newlib

**Verification:**
```bash
# Should show version 8.5.0
/opt/homebrew/opt/arm-none-eabi-gcc@8/bin/arm-none-eabi-gcc --version

# Should find stdint.h
/opt/homebrew/opt/arm-none-eabi-gcc@8/bin/arm-none-eabi-gcc -print-file-name=include/stdint.h
```

### Keyboard Details
- **Model**: Keychron V4 Max (60% layout, wireless-capable: 2.4 GHz + Bluetooth 5.1)
- **QMK Path**: `keyboards/keychron/v4_max/ansi` (⚠️ **REQUIRES KEYCHRON'S FORK**)
- **QMK Repository**: https://github.com/Keychron/qmk_firmware (NOT standard QMK repo!)
- **QMK Branch**: `wireless_playground` (required for V4 Max support)
- **MCU**: STM32L432 (ARM Cortex-M4)
- **Layout Macro**: `LAYOUT_60_ansi`
- **RGB**: Uses `RGB_MATRIX_ENABLE` (not `RGBLIGHT_ENABLE`)
- **Stock Firmware**: v4_max_ansi_v1.1.1_2507021559.bin (103,892 bytes)

### Compilation Issues Resolved

#### V4 Max Specific Issues:
1. **Wrong keyboard target**: Must use `keychron/v4_max/ansi` not `keychron/v4/ansi`
2. **Wrong layout macro**: V4 Max uses `LAYOUT_ansi_61` not `LAYOUT_60_ansi`
3. **RGBLIGHT conflict**: Must set `RGBLIGHT_ENABLE = no` in rules.mk (V4 Max uses RGB_MATRIX only)
4. **LTO linking error**: Must set `LTO_ENABLE = no` due to type mismatch in Keychron's wireless code (`connected_idle_time` declared as both uint32_t and uint16_t)
5. **Missing dependencies**: Must run `pip install -r requirements.txt` in Keychron's fork
6. **Git submodules**: Must run `git submodule update --init --recursive` after cloning

#### General QMK Issues:
1. **Duplicate `layer_state_set_user` functions**: Fixed by using `#elif` instead of separate `#ifdef` blocks for RGB_MATRIX vs RGBLIGHT
2. **`IGNORE_MOD_TAP_INTERRUPT` error**: Removed from config.h as it's now default behavior in modern QMK

## How to Compile Firmware

### ⚠️ CRITICAL: Must Use Keychron's QMK Fork

The V4 Max is NOT in the standard QMK repository. You must use Keychron's fork:

```bash
# If you haven't cloned Keychron's fork yet:
cd ~
git clone https://github.com/Keychron/qmk_firmware.git keychron_qmk_firmware
cd keychron_qmk_firmware
git checkout wireless_playground
git submodule update --init --recursive

# Install Python dependencies (required for Keychron's fork)
~/.local/pipx/venvs/qmk/bin/python -m pip install -r ~/keychron_qmk_firmware/requirements.txt

# Export PATH for build tools (must include ~/.local/bin for qmk CLI)
export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-binutils/bin:$HOME/.local/bin:$PATH"

# Create custom keymap directory (if it doesn't exist)
mkdir -p ~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom

# Copy custom keymap files from dotfiles
# NOTE: Config files are in ~/.dotfiles/DOTconfig.home.symlink/qmk/keychron_v4_max/
#       (symlinked to ~/.config/qmk/keychron_v4_max/)
cp ~/.dotfiles/DOTconfig.home.symlink/qmk/keychron_v4_max/{keymap.c,config.h,rules.mk} \
   ~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/

# Compile the keymap for V4 MAX (not V4!)
qmk compile -kb keychron/v4_max/ansi -km custom

# Output: ~/keychron_qmk_firmware/.build/keychron_v4_max_ansi_custom.bin
# (Note: output is in .build/ subdirectory, not root)

# Copy compiled firmware back to dotfiles for safekeeping
cp ~/keychron_qmk_firmware/.build/keychron_v4_max_ansi_custom.bin \
   ~/.dotfiles/DOTconfig.home.symlink/qmk/keychron_v4_max/
```

### One-Liner for Recompilation (after initial setup)

```bash
export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$HOME/.local/bin:$PATH" && \
cp ~/.dotfiles/DOTconfig.home.symlink/qmk/keychron_v4_max/{keymap.c,config.h,rules.mk} \
   ~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/ && \
cd ~/keychron_qmk_firmware && \
qmk compile -kb keychron/v4_max/ansi -km custom && \
cp .build/keychron_v4_max_ansi_custom.bin ~/.dotfiles/DOTconfig.home.symlink/qmk/keychron_v4_max/
```

## How to Flash Firmware

### ⚠️ CRITICAL: V4 vs V4 Max Firmware Differences

**DO NOT confuse V4 and V4 Max firmware!**
- **V4 Max**: Uses firmware files like `v4_max_ansi_v1.1.1_*.bin` (101KB)
- **Regular V4**: Uses different firmware files like `v4_us_v1.4.bin` (45KB)
- **Flashing the wrong firmware will brick the keyboard!**

Stock V4 Max firmware: https://www.keychron.com/pages/firmware-and-json-files-of-the-keychron-qmk-v-and-v-max-series-keyboards

### Entering Bootloader Mode

**RECOMMENDED METHOD - Hardware Reset Button:**
1. Unplug the keyboard
2. Remove the spacebar keycap (pull straight up)
3. Find the small reset button on the PCB (left side of spacebar switch)
4. Press and HOLD the reset button (use paperclip/toothpick)
5. While holding, plug in the USB cable
6. Hold for 2-3 seconds, then release
7. Keyboard is now in bootloader mode (DFU device)

**Alternative Method - Escape Key (WORKS WELL):**
1. Unplug keyboard
2. Hold Escape key (top left)
3. Plug in USB cable while holding Escape
4. Release after 2 seconds
5. ✅ Confirmed working - easier than removing spacebar!

**Note:** Pressing reset button while keyboard is running does NOT work - must unplug first.

### Flashing Stock Firmware (Command Line)
```bash
# Put keyboard in bootloader mode first (see above)

# Flash V4 Max stock firmware
dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D ~/.config/qmk/keychron_v4_max/v4_max_ansi_v1.1.1_2507021559.bin
```

### Flashing Custom QMK Firmware (NOT YET WORKING)
**NOTE: Custom firmware compilation target needs to be corrected first!**

```bash
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-binutils/bin:/opt/homebrew/opt/avr-binutils/bin:$PATH"
cd ~/qmk_firmware

# Put keyboard in bootloader mode first, then:
# TODO: Fix compilation target (currently uses keychron/v4/ansi which is WRONG)
qmk flash -kb keychron/v4/ansi -km custom  # ⚠️ This is for V4, not V4 Max!
```

## How to Modify the Keymap

### Edit the keymap file:
```bash
# Main keymap
open ~/qmk_firmware/keyboards/keychron/v4/ansi/keymaps/custom/keymap.c

# Configuration
open ~/qmk_firmware/keyboards/keychron/v4/ansi/keymaps/custom/config.h

# Build rules
open ~/qmk_firmware/keyboards/keychron/v4/ansi/keymaps/custom/rules.mk
```

### After editing, recompile:
```bash
cd ~/qmk_firmware
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-binutils/bin:/opt/homebrew/opt/avr-binutils/bin:$PATH"
qmk compile -kb keychron/v4/ansi -km custom
```

### Sync changes back to config directory:
```bash
cp ~/qmk_firmware/keyboards/keychron/v4/ansi/keymaps/custom/* ~/.config/qmk/keychron_v4_max/
```

## Testing Checklist

After flashing, verify these features:

- [ ] Tap Caps Lock → Produces Escape
- [ ] Hold Caps Lock + other key → Acts as Ctrl
- [ ] Tap Enter → Produces Enter
- [ ] Hold Enter + other key → Acts as Right Ctrl
- [ ] Physical Escape key → Produces Backtick/Tilde
- [ ] Hold Left Ctrl (lower left) → RGB turns blue
- [ ] Left Ctrl + H/J/K/L → Arrow keys work
- [ ] Left Ctrl + M/Comma → Home/End work
- [ ] Left Ctrl + U/I → Page Up/Down work
- [ ] Left Ctrl + 8/9/0 → Volume controls work
- [ ] Left Ctrl + Backspace → Forward delete works
- [ ] Right side of spacebar → Left/Down/Right arrows work
- [ ] Right Ctrl + / → Produces Up arrow
- [ ] Left Ctrl + S → Switches to numpad layer (RGB turns green)
- [ ] In numpad layer: UIOJKLM,. → Numbers work
- [ ] Numpad layer + D → Returns to base layer (RGB turns white)

## Known Issues / Limitations

1. **No mouse scroll mode**: The Karabiner Left Ctrl + W scroll layer is not implemented
2. **Wireless functionality**: QMK firmware only controls wired mode; wireless is handled by Keychron's proprietary firmware
3. **RGB color customization**: Colors are hardcoded; user may want to adjust HSV values in keymap.c
4. **V4 Max QMK Support**: Custom QMK firmware compilation target needs investigation - current target `keychron/v4/ansi` is for regular V4 and causes keyboard to be unresponsive on V4 Max

## Troubleshooting

### Keyboard Unresponsive After Flashing

**Symptoms:** Keyboard completely dead, no lights, no response

**Cause:** Wrong firmware flashed (V4 firmware on V4 Max, or corrupted custom firmware)

**Recovery:**
1. Enter bootloader mode using hardware reset button:
   - Unplug keyboard
   - Remove spacebar keycap
   - Press and hold reset button (left side of spacebar switch)
   - Plug in USB cable while holding button
   - Hold 2-3 seconds, release
2. Flash stock V4 Max firmware:
   ```bash
   dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D ~/.config/qmk/keychron_v4_max/v4_max_ansi_v1.1.1_2507021559.bin
   ```
3. Keyboard should work again with stock firmware

### Verifying Bootloader Mode
```bash
dfu-util -l
# Should show: Found DFU: [0483:df11] ... name="@Internal Flash  /0x08000000/..."
```

## Potential Future Improvements

1. **Add combo keys**: Use QMK's combo feature for additional shortcuts
2. **Tap dance**: Implement more complex tap behaviors
3. **Custom RGB animations**: Create layer-specific RGB patterns
4. **Macros**: Add commonly used text/command macros
5. **Leader key**: Implement vim-style leader key sequences
6. **Mouse keys**: Add mouse movement to a layer (though limited compared to Karabiner)

## QMK Resources

- [QMK Documentation](https://docs.qmk.fm/)
- [QMK Keycodes](https://docs.qmk.fm/keycodes)
- [Mod-Tap](https://docs.qmk.fm/mod_tap)
- [Layer Switching](https://docs.qmk.fm/feature_layers)
- [RGB Matrix](https://docs.qmk.fm/features/rgb_matrix)

## Important Environment Details

- **Working directory**: `/Users/thistooshallpass/Developer/GK6X`
- **Git repos**:
  - Main: `/Users/thistooshallpass/Developer/GK6X` (master branch, clean)
  - Additional: `/Users/thistooshallpass/.config/qmk`
  - Additional: `/Users/thistooshallpass/qmk_firmware`
  - Additional: `/Users/thistooshallpass/qmk_firmware/keyboards/keychron/v4/ansi/keymaps`
- **Platform**: macOS 26.2 (Darwin 25.2.0) on Apple Silicon
- **Shell**: zsh

## File Backups

Original configuration files (DO NOT MODIFY):
- Karabiner: `/Users/thistooshallpass/.config/karabiner/karabiner.json`
- GK6X: `/Users/thistooshallpass/Developer/GK6X/Build/UserData/655491117.txt`
- GK6X Lighting: `/Users/thistooshallpass/Developer/GK6X/Build/Data/lighting/*.le`

## Quick Reference for Next Agent

### To Compile Firmware:
```bash
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-binutils/bin:/opt/homebrew/opt/avr-binutils/bin:$PATH"
cd ~/keychron_qmk_firmware
qmk compile -kb keychron/v4_max/ansi -km custom
# Output: keychron_v4_max_ansi_custom.bin
cp keychron_v4_max_ansi_custom.bin ~/.config/qmk/keychron_v4_max/
```

### To Flash Firmware:
1. User unplugs keyboard, holds Escape, plugs in while holding, releases after 2 sec
2. Run: `dfu-util -l` to verify bootloader mode
3. Flash: `dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D ~/.config/qmk/keychron_v4_max/keychron_v4_max_ansi_custom.bin`

### Key Files:
- Keymap: `~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/keymap.c`
- Config: `~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/config.h`
- Rules: `~/keychron_qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/rules.mk`
- Backup: `~/.config/qmk/keychron_v4_max/` (copy here after compiling)

## Next Agent Actions

If user requests modifications:
1. Read this file to understand current state
2. Check `~/qmk_firmware/keyboards/keychron/v4/ansi/keymaps/custom/keymap.c` for current implementation
3. Make changes as requested
4. Recompile using the commands above
5. Update this file with new information
6. Remind user to flash updated firmware

If user reports issues:
1. Ask which specific feature is not working
2. Review the keymap.c implementation for that feature
3. Check QMK documentation for correct implementation
4. Test compilation after fixes
5. Update testing checklist in this file

## Communication Notes

- User prefers clear, step-by-step instructions
- User is comfortable with terminal commands
- User workplace restrictions: Cannot use Karabiner-Elements
- User is familiar with vim-style navigation (hence the HJKL preference)
