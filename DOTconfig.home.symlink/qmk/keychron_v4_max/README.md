# Keychron V4 Max Custom QMK Keymap

This keymap replicates your Karabiner configuration and GK6X keyboard settings for the Keychron V4 Max.

## Features Implemented

### Dual-Function Keys (Tap vs Hold)
- **Caps Lock**: Tap for `Escape`, Hold for `Left Ctrl`
- **Enter**: Tap for `Enter`, Hold for `Right Ctrl`

### Physical Key Remaps
- **Escape key** (upper left): Now `Backtick/Tilde` [`~]
- **Left Ctrl** (lower left): Activates VIM layer when held

### Right Side Arrow Keys
To the right of spacebar: `Left Arrow`, `Down Arrow`, `Right Arrow`, `Right Ctrl`
- **Right Ctrl + `/`**: Produces `Up Arrow`

### VIM Layer (Layer 2)
Activated by holding Left Ctrl (lower left key):

**Navigation:**
- `H` → Left Arrow
- `J` → Down Arrow
- `K` → Up Arrow
- `L` → Right Arrow
- `M` → Home
- `,` → End
- `U` → Page Up
- `I` → Page Down

**Editing:**
- `Backspace` → Forward Delete

**Volume:**
- `8` → Mute
- `9` → Volume Down
- `0` → Volume Up

**Layer Switching:**
- `S` → Switch to Numpad layer
- `D` → Switch to Base layer
- `Shift` → Still works as Shift

**Disabled Keys:**
Letters A, B, C, E, F, G, N, O, P, Q, R, T, V, W, X, Y, Z and numbers 1-7 are disabled in this layer.

### Numpad Layer (Layer 3)
Activated by pressing `S` in VIM layer:

```
U I O  →  7 8 9
J K L  →  4 5 6
M , .  →  1 2 3
N      →  0
; /    →  , .
```

**Layer Switching:**
- `S` → Switch to VIM layer
- `D` → Switch to Base layer

### RGB Lighting
- **Base Layer**: White
- **VIM Layer**: Blue
- **Numpad Layer**: Green

---

## Installation Instructions

### 1. Install QMK Prerequisites

#### macOS (via Homebrew):
```bash
brew install qmk/qmk/qmk
```

Or install the full toolchain:
```bash
brew install qmk/qmk/qmk
brew install --cask qmk-toolbox
```

### 2. Set Up QMK

```bash
# Clone QMK firmware
qmk setup

# This will clone the QMK repo to ~/qmk_firmware by default
```

### 3. Copy Your Keymap

```bash
# Create directory for your custom keymap
mkdir -p ~/qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom

# Copy your keymap files
cp ~/.config/qmk/keychron_v4_max/* ~/qmk_firmware/keyboards/keychron/v4_max/ansi/keymaps/custom/
```

**Note:** The exact path may vary. Check your QMK firmware directory structure:
```bash
ls ~/qmk_firmware/keyboards/keychron/
```

If `v4_max` doesn't exist, you may need to:
- Update QMK: `qmk setup -H ~/qmk_firmware`
- Or use VIA firmware (see Alternative Method below)

### 4. Compile the Firmware

```bash
cd ~/qmk_firmware

# Compile the firmware
qmk compile -kb keychron/v4_max/ansi -km custom
```

This will create a `.bin` file in the root of the QMK directory.

### 5. Flash the Keyboard

#### Using QMK Toolbox (Recommended):
1. Download and open [QMK Toolbox](https://github.com/qmk/qmk_toolbox/releases)
2. Open the compiled `.bin` file
3. Put your keyboard in bootloader mode:
   - Unplug the keyboard
   - Hold `Esc` key
   - Plug in the keyboard while holding `Esc`
   - Release `Esc`
4. Click "Flash" in QMK Toolbox

#### Using Command Line:
```bash
# Put keyboard in bootloader mode, then:
qmk flash -kb keychron/v4_max/ansi -km custom
```

---

## Alternative Method: Using VIA

If QMK compilation is too complex, the Keychron V4 Max supports VIA:

1. Download [VIA](https://www.caniusevia.com/)
2. Enable VIA mode on your keyboard (check Keychron documentation)
3. Use VIA's GUI to remap keys

**Limitations with VIA:**
- Harder to implement the "disabled keys" feature
- Less control over lighting
- May not support all advanced features (like Right Ctrl + / = Up)

---

## Testing Your Keymap

After flashing:

1. Test dual-function keys:
   - Tap Caps Lock → Should produce `Esc`
   - Hold Caps Lock, press another key → Should act as `Ctrl`
   - Same for Enter key

2. Test VIM layer:
   - Hold Left Ctrl (lower left)
   - Press H/J/K/L → Should move cursor like arrows
   - Press 8/9/0 → Should control volume

3. Test arrow keys:
   - Keys right of spacebar should be arrows
   - Right Ctrl + `/` → Should produce Up arrow

4. Test layer switching:
   - Hold Left Ctrl, press S → Should enter numpad mode (lighting turns green)
   - Press D → Should return to base layer

---

## Customization

### Adjust Tapping Speed
Edit `config.h`:
```c
#define TAPPING_TERM 200  // Change to 150-300ms based on preference
```

### Change RGB Colors
Edit `keymap.c`, in the `layer_state_set_user` function:
```c
case _VIM:
    rgb_matrix_sethsv_noeeprom(HSV_BLUE);  // Change HSV_BLUE to HSV_RED, HSV_GREEN, etc.
```

### Add More Keys to VIM Layer
Edit the `[_VIM]` layer in `keymap.c` and replace `KC_NO` with desired keycodes.

---

## Troubleshooting

### Keyboard not recognized in bootloader mode
- Try different USB cable
- Try different USB port
- Check Keychron docs for specific bootloader instructions

### Compilation errors
- Update QMK: `qmk setup -H ~/qmk_firmware`
- Check keyboard path: May be `keychron/v4/ansi` instead of `keychron/v4_max/ansi`

### Keymap not working as expected
- Verify you flashed the correct firmware
- Check `LAYOUT_60_ansi` matches your keyboard (may need `LAYOUT_60_ansi_tsangan` or similar)
- Test in VIA mode first to ensure hardware works

### Right Ctrl + / not producing Up arrow
- The `process_record_user` function may need adjustment
- Try using a layer with LT() instead

---

## Reference

- [QMK Documentation](https://docs.qmk.fm/)
- [Keychron V4 Max Page](https://www.keychron.com/products/keychron-v4-max-qmk-via-wireless-custom-mechanical-keyboard)
- [QMK Keycodes](https://docs.qmk.fm/keycodes)
- [VIA Documentation](https://www.caniusevia.com/docs/specification)

---

## Files in This Directory

- `keymap.c` - Main keymap configuration
- `rules.mk` - Build rules and feature flags
- `config.h` - Timing and behavior configuration
- `README.md` - This file
