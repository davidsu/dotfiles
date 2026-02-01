// Keychron V4 Max Custom Configuration

#pragma once

// Tapping configuration
#define TAPPING_TERM 200                    // Time in ms for tap vs hold
#define PERMISSIVE_HOLD                     // Makes tap and hold more reliable
#define IGNORE_MOD_TAP_INTERRUPT            // Helps prevent accidental mod activation

// Caps Lock as Ctrl/Esc configuration
#define TAPPING_FORCE_HOLD                  // Makes held keys repeat
#define RETRO_TAPPING                       // Tap on release if no other key pressed

// RGB Configuration (adjust colors to your preference)
#ifdef RGB_MATRIX_ENABLE
    #define RGB_MATRIX_STARTUP_MODE RGB_MATRIX_SOLID_COLOR
    #define RGB_MATRIX_STARTUP_HUE 0        // White
    #define RGB_MATRIX_STARTUP_SAT 0
    #define RGB_MATRIX_STARTUP_VAL RGB_MATRIX_MAXIMUM_BRIGHTNESS
#endif

#ifdef RGBLIGHT_ENABLE
    #define RGBLIGHT_SLEEP                   // Turn off RGB when computer sleeps
    #define RGBLIGHT_LAYERS                  // Enable lighting layers
#endif
