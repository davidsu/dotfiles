// Keychron V4 Max Custom Keymap
// Based on Karabiner config and GK6X configuration (655491117.txt)

#include QMK_KEYBOARD_H

// Layer definitions
enum layers {
    _BASE = 0,
    _VIM = 1,      // Layer2 from GK6X config - vim-style navigation
    _NUMPAD = 2    // Layer3 from GK6X config - numpad
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
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_PGUP, KC_PGDN, KC_NO,   KC_NO,   _______, _______, _______,
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
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_P7,   KC_P8,   KC_P9,   KC_NO,   _______, _______, _______,
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_P7,   KC_P8,   KC_P9,   _______, _______, _______, _______,
        _______, KC_NO,   TO(_VIM), TO(_BASE), KC_NO, KC_NO,   KC_NO,   KC_P4,   KC_P5,   KC_P6,   KC_PCMM, _______, _______,
        _______, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_P0,   KC_P1,   KC_P2,   KC_P3,   KC_PDOT, _______,
        _______, _______, _______,                   _______,                   _______, _______, _______, _______
    )
};

// Handle Right Ctrl + / = Up arrow
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    static bool rctrl_pressed = false;

    switch (keycode) {
        case KC_RCTL:
            rctrl_pressed = record->event.pressed;
            return true;

        case KC_SLSH:
            if (rctrl_pressed && record->event.pressed) {
                tap_code(KC_UP);
                return false; // Don't process the slash
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
        // Numpad layer: solid green - explicitly set all LEDs
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, 0, 255, 0);  // Green
        }
    } else {
        // Base layer: solid white - explicitly set all LEDs to clear VIM layer colors
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, 255, 255, 255);  // White
        }
    }

    return false;
}
#endif

