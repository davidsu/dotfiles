-- Hammerspoon config: Mod-tap + Cmd+Ctrl navigation
-- Replicates Karabiner functionality for MacBook keyboard

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
local MOD_TAP_TIMEOUT = 200  -- ms threshold for tap vs hold
local DEBUG = false  -- Set to true for debug logging

--------------------------------------------------------------------------------
-- State tracking
--------------------------------------------------------------------------------
local ctrlPressedTime = 0
local ctrlUsedAsModifier = false
local enterPressed = false
local enterPressedTime = 0
local enterUsedAsModifier = false
local enterOriginalMods = nil

--------------------------------------------------------------------------------
-- Cmd+Ctrl navigation (replaces fn+hjklnm from Karabiner)
--------------------------------------------------------------------------------
local navMods = {"cmd", "ctrl"}

-- Arrow keys: hjkl
hs.hotkey.bind(navMods, "h", function() hs.eventtap.keyStroke({}, "left", 0) end, nil, function() hs.eventtap.keyStroke({}, "left", 0) end)
hs.hotkey.bind(navMods, "j", function() hs.eventtap.keyStroke({}, "down", 0) end, nil, function() hs.eventtap.keyStroke({}, "down", 0) end)
hs.hotkey.bind(navMods, "k", function() hs.eventtap.keyStroke({}, "up", 0) end, nil, function() hs.eventtap.keyStroke({}, "up", 0) end)
hs.hotkey.bind(navMods, "l", function() hs.eventtap.keyStroke({}, "right", 0) end, nil, function() hs.eventtap.keyStroke({}, "right", 0) end)

-- Home/End: n/m
hs.hotkey.bind(navMods, "n", function() hs.eventtap.keyStroke({}, "home", 0) end)
hs.hotkey.bind(navMods, "m", function() hs.eventtap.keyStroke({}, "end", 0) end)

-- PageUp/PageDown: u/i
hs.hotkey.bind(navMods, "u", function() hs.eventtap.keyStroke({}, "pageup", 0) end, nil, function() hs.eventtap.keyStroke({}, "pageup", 0) end)
hs.hotkey.bind(navMods, "i", function() hs.eventtap.keyStroke({}, "pagedown", 0) end, nil, function() hs.eventtap.keyStroke({}, "pagedown", 0) end)

-- Forward delete: backspace
hs.hotkey.bind(navMods, "delete", function() hs.eventtap.keyStroke({}, "forwarddelete", 0) end, nil, function() hs.eventtap.keyStroke({}, "forwarddelete", 0) end)

-- With shift for selection (Cmd+Ctrl+Shift+hjkl)
local navModsShift = {"cmd", "ctrl", "shift"}
hs.hotkey.bind(navModsShift, "h", function() hs.eventtap.keyStroke({"shift"}, "left", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "left", 0) end)
hs.hotkey.bind(navModsShift, "j", function() hs.eventtap.keyStroke({"shift"}, "down", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "down", 0) end)
hs.hotkey.bind(navModsShift, "k", function() hs.eventtap.keyStroke({"shift"}, "up", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "up", 0) end)
hs.hotkey.bind(navModsShift, "l", function() hs.eventtap.keyStroke({"shift"}, "right", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "right", 0) end)
hs.hotkey.bind(navModsShift, "n", function() hs.eventtap.keyStroke({"shift"}, "home", 0) end)
hs.hotkey.bind(navModsShift, "m", function() hs.eventtap.keyStroke({"shift"}, "end", 0) end)
hs.hotkey.bind(navModsShift, "u", function() hs.eventtap.keyStroke({"shift"}, "pageup", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "pageup", 0) end)
hs.hotkey.bind(navModsShift, "i", function() hs.eventtap.keyStroke({"shift"}, "pagedown", 0) end, nil, function() hs.eventtap.keyStroke({"shift"}, "pagedown", 0) end)

--------------------------------------------------------------------------------
-- Mod-tap: Ctrl (Caps Lock) → Escape when tapped
--------------------------------------------------------------------------------
local ctrlTap
ctrlTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown}, function(event)
    local type = event:getType()
    local flags = event:getFlags()

    -- Track ctrl press/release for tap detection
    if type == hs.eventtap.event.types.flagsChanged then
        if DEBUG then
            print("flagsChanged - ctrl:", flags.ctrl, "shift:", flags.shift, "alt:", flags.alt, "cmd:", flags.cmd)
        end

        local isCtrl = flags.ctrl

        if isCtrl and ctrlPressedTime == 0 then
            -- Ctrl just pressed
            ctrlPressedTime = hs.timer.absoluteTime()
            ctrlUsedAsModifier = false
            if DEBUG then print("Ctrl DOWN - started timer") end
        elseif not isCtrl and ctrlPressedTime > 0 then
            -- Ctrl just released
            local elapsed = (hs.timer.absoluteTime() - ctrlPressedTime) / 1000000  -- convert to ms
            ctrlPressedTime = 0
            if DEBUG then print("Ctrl UP - elapsed:", elapsed, "usedAsMod:", ctrlUsedAsModifier) end
            local wasModifier = ctrlUsedAsModifier
            ctrlUsedAsModifier = false
            if elapsed < MOD_TAP_TIMEOUT and not wasModifier then
                -- Quick tap without using as modifier: send Escape
                if DEBUG then print("SENDING ESCAPE") end
                ctrlTap:stop()
                hs.eventtap.keyStroke({}, "escape", 0)
                ctrlTap:start()
            end
        end
        return false  -- don't block the event
    end

    -- Any key pressed while ctrl is down = ctrl used as modifier
    if type == hs.eventtap.event.types.keyDown and flags.ctrl then
        if DEBUG then print("Key pressed with Ctrl held - marked as modifier") end
        ctrlUsedAsModifier = true
    end

    return false  -- don't block
end)
ctrlTap:start()
print("ctrlTap eventtap started")

--------------------------------------------------------------------------------
-- Mod-tap: Enter → Right Ctrl when held, Enter when tapped
--------------------------------------------------------------------------------
local enterTap
enterTap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
    local keyCode = event:getKeyCode()
    local type = event:getType()

    -- Enter key code is 36
    if keyCode ~= 36 then
        -- Another key pressed while Enter is held
        if enterPressed and type == hs.eventtap.event.types.keyDown then
            enterUsedAsModifier = true
            -- Send Ctrl+key
            local flags = event:getFlags()
            flags.ctrl = true
            event:setFlags(flags)
        end
        return false
    end

    -- Enter key handling
    if type == hs.eventtap.event.types.keyDown then
        if not enterPressed then
            enterPressed = true
            enterPressedTime = hs.timer.absoluteTime()
            enterUsedAsModifier = false
            enterOriginalMods = event:getFlags()  -- capture original modifiers
            return true  -- block the keyDown, we'll handle it on keyUp
        end
        return true  -- block repeat
    elseif type == hs.eventtap.event.types.keyUp then
        if enterPressed then
            enterPressed = false
            local elapsed = (hs.timer.absoluteTime() - enterPressedTime) / 1000000
            enterPressedTime = 0
            local wasModifier = enterUsedAsModifier
            local mods = enterOriginalMods or {}
            enterUsedAsModifier = false
            enterOriginalMods = nil
            if not wasModifier then
                -- Stop tap, send Enter with original modifiers, restart tap
                enterTap:stop()
                local modList = {}
                if mods.shift then table.insert(modList, "shift") end
                if mods.cmd then table.insert(modList, "cmd") end
                if mods.alt then table.insert(modList, "alt") end
                -- Note: don't include ctrl since Enter-as-ctrl would have set wasModifier
                hs.eventtap.keyStroke(modList, "return", 0)
                enterTap:start()
            end
        end
        return true  -- block the keyUp (we handled it)
    end

    return false
end)
enterTap:start()
print("enterTap eventtap started")

--------------------------------------------------------------------------------
-- Startup notification
--------------------------------------------------------------------------------
hs.alert.show("Hammerspoon loaded", 1)
print("Hammerspoon config loaded")
print("Navigation: Cmd+Ctrl+[hjkl] arrows, Cmd+Ctrl+[ui] PgUp/PgDn, Cmd+Ctrl+[nm] Home/End")
print("Mod-tap: Ctrl tap=Escape, Enter hold=Ctrl")
