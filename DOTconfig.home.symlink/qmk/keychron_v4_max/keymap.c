// Keychron V4 Max Custom Keymap
// Based on Karabiner config and GK6X configuration (655491117.txt)

#include QMK_KEYBOARD_H

// Layer definitions
enum layers {
    _BASE = 0,
    _VIM = 1,       // Layer2 from GK6X config - vim-style navigation
    _NUMPAD = 2,    // Layer3 from GK6X config - numpad
    _BLUETOOTH = 3  // Bluetooth pairing layer - stock layout for Fn access
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    /*
     * BASE LAYER
     * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
     * │ ` │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │ Bkspc │
     * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
     * │ Tab │ Q │ W │ E │ R │ T │ Y │ U │ I │ O │ P │ [ │ ] │  \  │
     * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┤
     * │Esc/Ct│ A │ S │ D │ F │ G │ H │ J │ K │ L │ ; │ ' │ Ent/Ct │
     * ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴────────┤
     * │ Shift  │ Z │ X │ C │ V │ B │ N │ M │ , │ . │ / │   Shift  │
     * ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
     * │L_Vm│ Opt│ Cmd│        Space           │ ← │ ↓  │ →  │RCt*│
     * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
     * L_Vm = Left Ctrl activates VIM layer
     * Esc/Ct = Caps Lock → Esc when tapped, Ctrl when held
     * Ent/Ct = Enter → Enter when tapped, Ctrl when held
     * RCt* = Right Ctrl (RCtrl + / = Up arrow)
     */
    [_BASE] = LAYOUT_ansi_61(
        KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS, KC_EQL,  KC_BSPC,
        KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_LBRC, KC_RBRC, KC_BSLS,
        MT(MOD_LCTL, KC_ESC), KC_A, KC_S, KC_D, KC_F, KC_G, KC_H, KC_J, KC_K, KC_L, KC_SCLN, KC_QUOT, MT(MOD_RCTL, KC_ENT),
        KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_RSFT,
        MO(_VIM), KC_LALT, KC_LGUI,                   KC_SPC,                    KC_LEFT, KC_DOWN, KC_RGHT, KC_RCTL
    ),

    /*
     * VIM LAYER (Layer2 from GK6X config)
     * Activated by holding Left Ctrl (lower left key)
     * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
     * │   │ X │ X │ X │ X │ X │ X │ X │Mut│V- │V+ │   │   │  Del  │
     * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
     * │     │ X │ X │ X │ X │ X │ X │PgU│PgD│ X │ X │   │   │     │
     * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┤
     * │      │ X │L3 │L0 │ X │ X │ ← │ ↓ │ ↑ │ → │   │   │        │
     * ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴────────┤
     * │  Shft  │ X │ X │ X │ X │ X │ X │Hom│End│ X │ X │          │
     * ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
     * │    │    │    │                        │   │    │    │    │
     * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
     * X = Disabled keys (from GK6X config lines 166-259)
     * L3 = Switch to Numpad layer (S key)
     * L0 = Switch to Base layer (D key)
     * RGB lighting: Blue color for vim layer
     */
    [_VIM] = LAYOUT_ansi_61(
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_MUTE, KC_VOLD, KC_VOLU, _______, _______, KC_DEL,
        _______, TO(_BASE), TO(_BASE), KC_TRNS, TO(_NUMPAD), KC_NO, KC_NO, KC_PGUP, KC_PGDN, KC_NO, KC_NO, _______, _______, _______,
        _______, KC_NO,   TO(_NUMPAD), TO(_BASE), KC_NO, KC_NO, KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT, _______, _______, _______,
        KC_LSFT, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_HOME, KC_END,  KC_NO,   KC_NO,   _______,
        _______, _______, _______,                   _______,                   _______, _______, _______, _______
    ),

    /*
     * NUMPAD LAYER (Layer3 from GK6X config)
     * Activated by pressing S in VIM layer
     * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
     * │   │ X │ X │ X │ X │ X │ X │ 7 │ 8 │ 9 │ X │   │   │       │
     * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
     * │     │ X │ X │ X │ X │ X │ X │ 7 │ 8 │ 9 │   │   │   │     │
     * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┤
     * │      │ X │L2 │L0 │ X │ X │ X │ 4 │ 5 │ 6 │ , │   │        │
     * ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴────────┤
     * │        │ X │ X │ X │ X │ X │ 0 │ 1 │ 2 │ 3 │ . │          │
     * ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
     * │    │    │    │                        │   │    │    │    │
     * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
     * L2 = Switch to VIM layer (S key)
     * L0 = Switch to Base layer (D key)
     * RGB lighting: Green color for numpad layer
     */
    [_NUMPAD] = LAYOUT_ansi_61(
        _______, KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    _______, _______, _______,
        _______, TO(_BASE), TO(_BASE), TO(_VIM), KC_TRNS, KC_NO, KC_NO, KC_7, KC_8, KC_9, KC_NO, _______, _______, _______,
        _______, KC_NO,   TO(_VIM), TO(_BASE), KC_NO, KC_NO,   KC_NO,   KC_4,    KC_5,    KC_6,    KC_COMM, _______, _______,
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_0,    KC_1,    KC_2,    KC_3,    KC_DOT,  _______,
        _______, _______, _______,                   _______,                   _______, _______, _______, _______
    ),

    /*
     * BLUETOOTH LAYER
     * Activated by Right Ctrl + Esc
     * Stock layout to enable Bluetooth pairing via Fn+Q/W/E
     * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
     * │Esc│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │ Bkspc │
     * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
     * │ Tab │ Q │ W │ E │ R │ T │ Y │ U │ I │ O │ P │ [ │ ] │  \  │
     * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┤
     * │ Caps │ A │ S │ D │ F │ G │ H │ J │ K │ L │ ; │ ' │ Enter │
     * ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴────────┤
     * │ Shift  │ Z │ X │ C │ V │ B │ N │ M │ , │ . │ / │   Shift  │
     * ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
     * │Ctrl│ Alt│ Cmd│        Space           │RCmd│Fn1 │Fn3 │RCt │
     * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
     * Fn+Q/W/E (hold 4 sec) = Pair to Bluetooth device 1/2/3
     * RGB: Q, W, E, Fn1 lit in cyan (Bluetooth/media/RGB control keys)
     */
    [_BLUETOOTH] = LAYOUT_ansi_61(
        KC_ESC,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS, KC_EQL,  KC_BSPC,
        KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_LBRC, KC_RBRC, KC_BSLS,
        KC_CAPS, KC_A,    KC_S,    KC_D,    KC_F,    KC_G,    KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, KC_ENT,
        KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_RSFT,
        KC_LCTL, KC_LALT, KC_LGUI,                   KC_SPC,                    KC_RGUI, KC_TRNS, KC_TRNS, KC_RCTL
    )
};

// State tracking for Ctrl keys and RGB toggle
static bool lctrl_pressed = false;  // Physical left ctrl
static bool rctrl_pressed = false;  // Physical right ctrl
static bool base_rgb_enabled = true;  // Toggle for base layer RGB

// Handle Ctrl + combinations and numpad layer special keys
bool process_record_user(uint16_t keycode, keyrecord_t *record) {

    switch (keycode) {
        case KC_LCTL:
            lctrl_pressed = record->event.pressed;
            return true;

        case KC_RCTL:
            rctrl_pressed = record->event.pressed;
            return true;

        case KC_GRV:
            // Ctrl + ` (physical Escape key) = Switch to Bluetooth layer
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed) {
                layer_clear();
                layer_on(_BLUETOOTH);
                return false;
            }
            return true;

        case KC_DOT:
            // In numpad layer: Shift+/ (?) produces / for division
            if (get_highest_layer(layer_state) == _NUMPAD &&
                get_mods() & MOD_MASK_SHIFT &&
                record->event.pressed) {
                // Remove shift, send slash, restore shift
                uint8_t mods = get_mods();
                del_mods(MOD_MASK_SHIFT);
                tap_code(KC_SLSH);
                set_mods(mods);
                return false;
            }
            return true;

        case KC_BSLS:
            // Ctrl + \ = Toggle base layer RGB
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed) {
                base_rgb_enabled = !base_rgb_enabled;
                return false;
            }
            // In numpad layer: \ produces /
            if (get_highest_layer(layer_state) == _NUMPAD && record->event.pressed) {
                tap_code(KC_SLSH);
                return false;
            }
            return true;

        case KC_SLSH:
            // Ctrl + / = Up arrow (only when not in numpad layer)
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed &&
                get_highest_layer(layer_state) != _NUMPAD) {
                tap_code(KC_UP);
                return false;
            }
            return true;

        case KC_Q:
        case KC_W:
            // Ctrl + Q or W = Switch to Base layer
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed) {
                layer_clear();
                return false;
            }
            return true;

        case KC_E:
            // Ctrl + E = Switch to VIM layer
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed) {
                layer_clear();
                layer_on(_VIM);
                return false;
            }
            return true;

        case KC_R:
            // Ctrl + R = Switch to Numpad layer
            if ((lctrl_pressed || rctrl_pressed) && record->event.pressed) {
                layer_clear();
                layer_on(_NUMPAD);
                return false;
            }
            return true;
    }
    return true;
}

// RGB lighting layer indication (matches GK6X lighting config)
#ifdef RGB_MATRIX_ENABLE

// Per-key RGB colors for VIM layer (from GK6X vimLike.le)
// LED indices verified from g_led_config in ansi.c (2026-02-01)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    if (get_highest_layer(layer_state) == _VIM) {
        // Turn off all keys first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, 0, 0, 0);
        }

        // S & D (layer switching): Dark blue 0x020020
        rgb_matrix_set_color(30, 2, 0, 32);  // S (was 29, fixed to 30)
        rgb_matrix_set_color(31, 2, 0, 32);  // D (was 30, fixed to 31)

        // 8, 9, 0 (volume controls): White 0xFFFFFF
        rgb_matrix_set_color(8, 255, 255, 255);   // 8
        rgb_matrix_set_color(9, 255, 255, 255);   // 9
        rgb_matrix_set_color(10, 255, 255, 255);  // 0

        // U & I (Page Up/Down): Orange 0xFFA500
        rgb_matrix_set_color(21, 255, 165, 0);  // U
        rgb_matrix_set_color(22, 255, 165, 0);  // I

        // M & Comma (Home/End): Green 0x00FF00
        rgb_matrix_set_color(48, 0, 255, 0);  // M (was 47, fixed to 48)
        rgb_matrix_set_color(49, 0, 255, 0);  // Comma (was 48, fixed to 49)

        // Backspace (Forward Delete): Red 0xFF0000
        rgb_matrix_set_color(13, 255, 0, 0);  // Backspace

        // H, J, K, L (arrow keys): Purple 0x800080
        rgb_matrix_set_color(34, 128, 0, 128);  // H (was 33, fixed to 34)
        rgb_matrix_set_color(35, 128, 0, 128);  // J (was 34, fixed to 35)
        rgb_matrix_set_color(36, 128, 0, 128);  // K (was 35, fixed to 36)
        rgb_matrix_set_color(37, 128, 0, 128);  // L (was 36, fixed to 37)

    } else if (get_highest_layer(layer_state) == _NUMPAD) {
        // Turn off all keys first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, 0, 0, 0);
        }

        // S & D (layer switching): Dark blue 0x020020
        rgb_matrix_set_color(30, 2, 0, 32);  // S
        rgb_matrix_set_color(31, 2, 0, 32);  // D

        // Numbers 1-9 (U, I, O, J, K, L, M, Comma, Period): Purple 0x800080
        rgb_matrix_set_color(21, 128, 0, 128);  // U (7)
        rgb_matrix_set_color(22, 128, 0, 128);  // I (8)
        rgb_matrix_set_color(23, 128, 0, 128);  // O (9)
        rgb_matrix_set_color(35, 128, 0, 128);  // J (4)
        rgb_matrix_set_color(36, 128, 0, 128);  // K (5)
        rgb_matrix_set_color(37, 128, 0, 128);  // L (6)
        rgb_matrix_set_color(48, 128, 0, 128);  // M (1)
        rgb_matrix_set_color(49, 128, 0, 128);  // Comma (2)
        rgb_matrix_set_color(50, 128, 0, 128);  // Period (3)

        // Number 0 (N): Green 0x00ff00
        rgb_matrix_set_color(47, 0, 255, 0);  // N (0)

        // Semicolon and Slash (numpad comma/period): Red 0xFF0000
        rgb_matrix_set_color(38, 255, 0, 0);  // Semicolon (numpad comma)
        rgb_matrix_set_color(51, 255, 0, 0);  // Slash (numpad period)

        // Backslash (division): Red 0xFF0000
        rgb_matrix_set_color(27, 255, 0, 0);  // Backslash

    } else if (get_highest_layer(layer_state) == _BLUETOOTH) {
        // Turn off all keys first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, 0, 0, 0);
        }

        // Bluetooth pairing indicators in cyan (0x00FFFF)
        rgb_matrix_set_color(15, 0, 255, 255);  // Q (Fn1+Q = BT device 1)
        rgb_matrix_set_color(16, 0, 255, 255);  // W (Fn1+W = BT device 2)
        rgb_matrix_set_color(17, 0, 255, 255);  // E (Fn1+E = BT device 3)
        rgb_matrix_set_color(58, 0, 255, 255);  // Fn1 (Bluetooth/media/RGB control key)

    } else {
        // Base layer: check if RGB is enabled
        if (base_rgb_enabled) {
            // Solid white - explicitly set all LEDs to clear VIM layer colors
            for (uint8_t i = led_min; i < led_max; i++) {
                rgb_matrix_set_color(i, 255, 255, 255);  // White
            }
        } else {
            // RGB disabled - turn off all LEDs
            for (uint8_t i = led_min; i < led_max; i++) {
                rgb_matrix_set_color(i, 0, 0, 0);  // Off
            }
        }
    }

    // Visual indicator: ESC/Q/W/E/R in red when physical Ctrl is pressed (all layers)
    // Shows available layer switching keys: Ctrl+Esc/Q/W/E/R
    if (lctrl_pressed || rctrl_pressed) {
        rgb_matrix_set_color(0, 255, 0, 0);   // ESC (Ctrl+Esc → Bluetooth)
        rgb_matrix_set_color(15, 255, 0, 0);  // Q (Ctrl+Q → Base)
        rgb_matrix_set_color(16, 255, 0, 0);  // W (Ctrl+W → Base)
        rgb_matrix_set_color(17, 255, 0, 0);  // E (Ctrl+E → VIM)
        rgb_matrix_set_color(18, 255, 0, 0);  // R (Ctrl+R → Numpad)
    }

    return false;
}
#endif

