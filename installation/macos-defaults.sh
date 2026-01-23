#!/usr/bin/env bash

# Print dialog quits when finished
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable quarantine warnings for downloaded files
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g NSWindowResizeTime -float 0.001
defaults write -g QLPanelAnimationDuration -float 0
defaults write -g NSToolbarFullScreenAnimationDuration -float 0
defaults write com.apple.finder DisableAllAnimations -bool true

# Fast keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 1

# Mouse settings
defaults write -g com.apple.mouse.scaling 3.0                 # Tracking speed: fast
defaults write -g com.apple.swipescrolldirection -bool false  # Natural scrolling: off (applies to both mouse and trackpad)
defaults write -g com.apple.mouse.doubleClickThreshold 0.4    # Double-click speed: fast
defaults write -g com.apple.scrollwheel.scaling 0.5           # Scrolling speed: medium

# Trackpad - Point & Click
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2  # Look up with three fingers
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true                    # Tap to click
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true          # Secondary click enabled
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 1               # Click: medium
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true             # Force click: off

# Trackpad - Scroll & Zoom
defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true               # Zoom in/out: pinch
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 1  # Smart zoom
defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true              # Rotate with two fingers

# Dock: scale effect, fast autohide, and clear default apps
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock autohide-time-modifier -float 0

# Clear all pinned apps and hide "recent" apps section
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock show-recents -bool false

# Restart affected apps
killall Dock Finder 2>/dev/null

echo "macOS defaults applied. Some changes may require logout."
