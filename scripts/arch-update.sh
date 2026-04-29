#!/bin/bash

# Arch Linux Background Prep Script
# Purpose: Syncs repos and downloads packages safely. 
# Triggers a notification for the user to finish the update manually.

# Configuration
LOG_DIR="/var/log/arch-update"
LOG_FILE="${LOG_DIR}/prep-$(date +%Y%m%d-%H%M%S).log"
ERROR_LOG="${LOG_DIR}/errors.log"
MAX_LOG_AGE=30

# Create necessary directories
sudo mkdir -p "$LOG_DIR"
sudo chown $USER:$USER "$LOG_DIR" 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
    exit 1
}

# 1. Connectivity Check
if ! ping -c 1 archlinux.org > /dev/null 2>&1; then
    log "No internet. Skipping this week."
    exit 0
fi

# 2. Sync and Download (The -w flag is the magic "download only" part)
log "Refreshing databases and downloading packages (safe)..."
if ! sudo pacman -Syuw --noconfirm >> "$LOG_FILE" 2>&1; then
    error_exit "Failed to download official updates."
fi

# 3. Check for AUR updates (if yay/paru is installed)
# Note: AUR helpers usually don't have a simple 'download only' flag like pacman,
# so we just check for their existence to notify you.
AUR_COUNT=0
if command -v yay &> /dev/null; then
    AUR_COUNT=$(yay -Qua | wc -l)
elif command -v paru &> /dev/null; then
    AUR_COUNT=$(paru -Qua | wc -l)
fi

# 4. Count pending official updates
REPO_COUNT=$(checkupdates | wc -l)
TOTAL_UPDATES=$((REPO_COUNT + AUR_COUNT))

# 5. Notify the user
if [ "$TOTAL_UPDATES" -gt 0 ]; then
    log "Found $TOTAL_UPDATES updates. Sending notification..."
    
    # Identify the active user to send a desktop notification
    USER_NAME=$(who | awk '{print $1}' | head -n 1)
    USER_ID=$(id -u "$USER_NAME")
    
    # Send notification (requires libnotify installed)
    sudo -u "$USER_NAME" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$USER_ID"/bus \
    notify-send -u critical -i software-update-available \
    "Arch Updates Ready" "There are $TOTAL_UPDATES updates waiting. Run 'sudo pacman -Syu' to finish."
else
    log "System is already up to date."
fi

# 6. Housekeeping (Rotate logs)
find "$LOG_DIR" -name "*.log" -type f -mtime +$MAX_LOG_AGE -delete 2>/dev/null

exit 0
