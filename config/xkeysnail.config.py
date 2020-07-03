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
define_keymap(re.compile("Tilix|Konsole"), {
    # copy/paste
    K("Super-c"): K("C-Shift-c"),
    K("Super-v"): K("C-Shift-v"),
    #new tab
    K("Super-t"): K("C-Shift-t"),
    #quit/close
    K("Super-q"): K("C-Shift-q"),
    K("Super-w"): K("C-Shift-w"),
    #zoom
    K("Super-EQUAL"): K("C-Shift-EQUAL"),
    K("Super-MINUS"): K("C-MINUS"),
}, "Copy paste in tilix terminal")

# Keybindings for Firefox/Chrome
define_keymap(re.compile("Firefox|Google-chrome|Brave|Vivaldi"), {
    K("Super-l"): K("C-l"),
    K("Super-r"): K("C-r"),
    K("Super-l"): K("C-l"),
}, "Browser")

define_keymap(None, {
    K("Super-EQUAL"): K("C-EQUAL"),
    K("Super-MINUS"): K("C-MINUS"),
    K("Super-a"): K("C-a"),
}, "Browser")
