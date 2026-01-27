#!/usr/bin/env bun

import { execSync } from 'child_process'

function setDefault(domain: string, key: string, type: string, value: string) {
  execSync(`defaults write ${domain} "${key}" -${type} ${value}`, { stdio: 'inherit' })
}

function setGlobalDefault(key: string, type: string, value: string) {
  setDefault('-g', key, type, value)
}

function setPrintDefaults() {
  setDefault('com.apple.print.PrintingPrefs', 'Quit When Finished', 'bool', 'true')
}

function setSecurityDefaults() {
  setDefault('com.apple.LaunchServices', 'LSQuarantine', 'bool', 'false')
}

function setAnimationDefaults() {
  setGlobalDefault('NSAutomaticWindowAnimationsEnabled', 'bool', 'false')
  setGlobalDefault('NSWindowResizeTime', 'float', '0.001')
  setGlobalDefault('QLPanelAnimationDuration', 'float', '0')
  setGlobalDefault('NSToolbarFullScreenAnimationDuration', 'float', '0')
  setDefault('com.apple.finder', 'DisableAllAnimations', 'bool', 'true')
}

function setKeyboardDefaults() {
  setDefault('NSGlobalDomain', 'KeyRepeat', 'int', '1')
}

function setMouseDefaults() {
  setGlobalDefault('com.apple.mouse.scaling', 'float', '3.0')
  setGlobalDefault('com.apple.swipescrolldirection', 'bool', 'false')
  setGlobalDefault('com.apple.mouse.doubleClickThreshold', 'float', '0.4')
  setGlobalDefault('com.apple.scrollwheel.scaling', 'float', '0.5')
}

function setTrackpadPointAndClickDefaults() {
  setDefault('com.apple.AppleMultitouchTrackpad', 'TrackpadThreeFingerTapGesture', 'int', '2')
  setDefault('com.apple.AppleMultitouchTrackpad', 'Clicking', 'bool', 'true')
  setDefault('com.apple.AppleMultitouchTrackpad', 'TrackpadRightClick', 'bool', 'true')
  setDefault('com.apple.AppleMultitouchTrackpad', 'ActuationStrength', 'int', '1')
  setDefault('com.apple.AppleMultitouchTrackpad', 'ForceSuppressed', 'bool', 'true')
}

function setTrackpadScrollAndZoomDefaults() {
  setDefault('com.apple.AppleMultitouchTrackpad', 'TrackpadPinch', 'bool', 'true')
  setDefault('com.apple.AppleMultitouchTrackpad', 'TrackpadTwoFingerDoubleTapGesture', 'int', '1')
  setDefault('com.apple.AppleMultitouchTrackpad', 'TrackpadRotate', 'bool', 'true')
}

function setDockDefaults() {
  setDefault('com.apple.dock', 'mineffect', 'string', 'scale')
  setDefault('com.apple.dock', 'autohide-time-modifier', 'float', '0')
  setDefault('com.apple.dock', 'persistent-apps', 'array', '')
  setDefault('com.apple.dock', 'show-recents', 'bool', 'false')
}

function setAppearanceDefaults() {
  execSync(`osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'`)
}

function restartAffectedApps() {
  execSync('killall Dock Finder 2>/dev/null || true', { stdio: 'inherit' })
}

function applyMacOSDefaults() {
  setPrintDefaults()
  setSecurityDefaults()
  setAnimationDefaults()
  setKeyboardDefaults()
  setMouseDefaults()
  setTrackpadPointAndClickDefaults()
  setTrackpadScrollAndZoomDefaults()
  setDockDefaults()
  setAppearanceDefaults()
  restartAffectedApps()

  console.log('macOS defaults applied. Some changes may require logout.')
}

if (import.meta.main) {
  applyMacOSDefaults()
}

export { applyMacOSDefaults }
