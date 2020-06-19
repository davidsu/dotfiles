from xkeysnail.transform import *
import re
define_multipurpose_modmap(
    # Enter is enter when pressed and released. Control when held down.
    {Key.ENTER: [Key.ENTER, Key.RIGHT_CTRL],

    # Capslock is escape when pressed and released. Control when held down.
    Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL]}
)
# [Global modemap] copy/paste ala-Mac
define_keymap(lambda wm_class: wm_class not in ("Tilix"), {
    K("Super-c"): K("C-c"),
    K("Super-v"): K("C-v"),
})
define_keymap(re.compile("Tilix"), {
    K("Super-c"): K("C-Shift-c"),
    K("Super-v"): K("C-Shift-v"),
}, "Copy paste in tilix terminal")

# Keybindings for Firefox/Chrome
define_keymap(re.compile("Firefox|Google-chrome|Brave|Vivaldi"), {
    K("Super-l"): K("C-l"),
}, "Browser")
