#!/bin/bash

# Define the command for your alias
CONFIG_CMD="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# 1. Update the system state files
# -Qqen: Native packages (Explicitly installed, not from AUR)
pacman -Qqen > "$HOME/pkglist.txt"

# -Qqem: AUR packages (Foreign packages not in sync DB)
pacman -Qqem > "$HOME/aurlist.txt"

# Update Systemd services
systemctl list-unit-files --state=enabled --no-legend --no-pager > "$HOME/enabled_system_services.txt"
systemctl --user list-unit-files --state=enabled --no-legend --no-pager > "$HOME/enabled_user_services.txt"

# 2. Stage changes
# Explicitly add the state files in case they are new, 
# then 'add -u' for all other tracked dotfiles (Neovim, Hyprland, etc.)
$CONFIG_CMD add "$HOME/pkglist.txt" "$HOME/aurlist.txt" "$HOME/enabled_system_services.txt" "$HOME/enabled_user_services.txt"
$CONFIG_CMD add -u

# 3. Commit and Push if there are changes
if ! $CONFIG_CMD diff --cached --exit-code --quiet; then
    $CONFIG_CMD commit -m "Auto-update: $(date +'%Y-%m-%d %H:%M')"
    
    $CONFIG_CMD push
else
    echo "No changes in tracked files. Skipping commit."
fi
