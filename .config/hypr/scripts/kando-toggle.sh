#!/bin/bash

# We use the full path to 'rg' to ignore any aliases
# -q in ripgrep still means 'quiet'
if hyprctl activewindow -j | /usr/bin/rg -q "kando"; then
    ydotool click 0xC1
else
    hyprctl dispatch global menu.kando.Kando:windows-menu
fi
