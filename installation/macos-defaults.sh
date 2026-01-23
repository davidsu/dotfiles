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

# Dock: scale effect, fast autohide
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock autohide-time-modifier -float 0

# Restart affected apps
killall Dock Finder 2>/dev/null

echo "macOS defaults applied. Some changes may require logout."
