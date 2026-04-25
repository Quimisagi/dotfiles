#!/bin/bash

# 1. Get the PID of the active Kitty window via Hyprland
active_pid=$(hyprctl activewindow -j | jq -r '.pid')

if [ -n "$active_pid" ] && [ "$active_pid" != "null" ]; then
    # 2. Find the youngest child process (usually the shell or a running app)
    # This helps get the actual CWD if you're deep in a subshell
    child_pid=$(pgrep -P "$active_pid" | tail -n 1)
    
    # Use the child PID if found, otherwise stick to the parent
    target_pid=${child_pid:-$active_pid}
    
    # 3. Get the CWD from the proc filesystem
    if [ -d "/proc/$target_pid/cwd" ]; then
        cwd=$(readlink -f "/proc/$target_pid/cwd")
        kitty --directory "$cwd" &
    else
        kitty &
    fi
else
    # Fallback if no window is active or Hyprland isn't responding
    kitty &
fi
