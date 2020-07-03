from xkeysnail.transform import *
import re
define_multipurpose_modmap(
    # Enter is enter when pressed and released. Control when held down.
    {Key.ENTER: [Key.ENTER, Key.RIGHT_CTRL],

    # Capslock is escape when pressed and released. Control when held down.
    Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL]}
)

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

define_keymap(None, {
    K("Super-EQUAL"): K("C-EQUAL"),
    K("Super-MINUS"): K("C-MINUS"),
    K("Super-c"): K("C-c"),
    K("Super-v"): K("C-v"),
    K("Super-a"): K("C-a"),
    K("Super-w"): K("C-w"),
    K("Super-q"): K("C-q"),
    K("Super-l"): K("C-l"),
    K("Super-r"): K("C-r"),
}, "Browser")
