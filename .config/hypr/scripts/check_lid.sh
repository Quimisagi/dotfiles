#!/usr/bin/env bash

# Check the hardware state of the lid
#
sleep 1.0
if grep -q open /proc/acpi/button/lid/*/state; then
    # Lid is open: Enable laptop screen
    hyprctl keyword monitor "eDP-1, 1920x1080@60, 1920x0, 1"
else
    # Lid is closed: Disable laptop screen
    hyprctl keyword monitor "eDP-1, disable"
fi
