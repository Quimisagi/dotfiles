#!/bin/bash

# Arch Linux Periodic Update Script
# Recommended: Run weekly via systemd timer or cron

# Configuration
LOG_DIR="/var/log/arch-update"
LOG_FILE="${LOG_DIR}/update-$(date +%Y%m%d-%H%M%S).log"
ERROR_LOG="${LOG_DIR}/errors.log"
BACKUP_DIR="/var/backups/arch-update"
PACMAN_CONF="/etc/pacman.conf"
MAX_LOG_AGE=30  # days

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create necessary directories
sudo mkdir -p "$LOG_DIR" "$BACKUP_DIR"
sudo chown -R $USER:$USER "$LOG_DIR" 2>/dev/null || true

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "${RED}ERROR: $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
    exit 1
}

# Check if running as root (should not be run as root)
if [[ $EUID -eq 0 ]]; then
    error_exit "This script should not be run as root. Run as normal user with sudo privileges."
fi

# Check internet connectivity
log "Checking internet connectivity..."
if ! ping -c 1 archlinux.org > /dev/null 2>&1; then
    error_exit "No internet connection. Please check your network."
fi

# Check if another instance is running
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
    error_exit "Another update instance is already running."
fi

# Backup critical files
log "Creating backups of critical system files..."
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup-$BACKUP_DATE"

sudo mkdir -p "$BACKUP_PATH"
sudo cp /etc/pacman.conf "$BACKUP_PATH/" 2>/dev/null
sudo cp /etc/makepkg.conf "$BACKUP_PATH/" 2>/dev/null
sudo pacman -Qqe > "$BACKUP_PATH/pkglist.txt" 2>/dev/null
log "Backup created at $BACKUP_PATH"

# Start update process
log "${GREEN}Starting Arch Linux system update...${NC}"

# Refresh package databases
log "Refreshing package databases..."
if ! sudo pacman -Sy --noconfirm >> "$LOG_FILE" 2>&1; then
    error_exit "Failed to refresh package databases"
fi

# Check for partial upgrade warnings
log "Checking system integrity..."
if ! sudo pacman -Dk >> "$LOG_FILE" 2>&1; then
    log "${YELLOW}Warning: Some packages have broken dependencies${NC}"
fi

# Perform full system upgrade
log "Performing full system upgrade..."
if sudo pacman -Su --noconfirm >> "$LOG_FILE" 2>&1; then
    log "${GREEN}System upgrade completed successfully${NC}"
else
    error_exit "System upgrade failed. Check $LOG_FILE for details"
fi

# Check for orphaned packages
log "Checking for orphaned packages..."
ORPHANS=$(pacman -Qtdq 2>/dev/null)
if [[ -n "$ORPHANS" ]]; then
    echo "$ORPHANS" | wc -l | xargs -I {} log "${YELLOW}Found {} orphaned packages${NC}"
    read -p "Remove orphaned packages? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -Rns --noconfirm $ORPHANS >> "$LOG_FILE" 2>&1
        log "Removed orphaned packages"
    fi
else
    log "No orphaned packages found"
fi

# Clean package cache (keep last 2 versions)
log "Cleaning package cache..."
if ! sudo paccache -r -k 2 >> "$LOG_FILE" 2>&1; then
    log "${YELLOW}Warning: paccache cleanup failed (install pacman-contrib if needed)${NC}"
fi

# Clean orphaned cache (optional)
if command -v paccache &> /dev/null; then
    sudo paccache -ruk0 >> "$LOG_FILE" 2>&1
    log "Cleaned uninstalled package cache"
fi

# Check for kernel updates and suggest reboot
if grep -q "linux" <<< "$(pacman -Qk 2>/dev/null | grep -i "warning")"; then
    log "${YELLOW}Kernel updated. System reboot recommended.${NC}"
    echo "Kernel updated on $(date)" >> "$LOG_DIR/reboot-required"
fi

# Update AUR packages if yay/paru is installed
if command -v yay &> /dev/null; then
    log "Updating AUR packages with yay..."
    if yay -Sua --noconfirm --removemake >> "$LOG_FILE" 2>&1; then
        log "AUR packages updated successfully"
    else
        log "${YELLOW}Warning: Some AUR packages failed to update${NC}"
    fi
elif command -v paru &> /dev/null; then
    log "Updating AUR packages with paru..."
    if paru -Sua --noconfirm >> "$LOG_FILE" 2>&1; then
        log "AUR packages updated successfully"
    else
        log "${YELLOW}Warning: Some AUR packages failed to update${NC}"
    fi
fi

# Rotate old logs
log "Cleaning logs older than $MAX_LOG_AGE days..."
find "$LOG_DIR" -name "*.log" -type f -mtime +$MAX_LOG_AGE -delete 2>/dev/null
find "$BACKUP_DIR" -type d -mtime +90 -exec rm -rf {} + 2>/dev/null

# System health check after update
log "Performing post-update health check..."
echo "=== System Health Check ===" >> "$LOG_FILE"
echo "Kernel version: $(uname -r)" >> "$LOG_FILE"
echo "Uptime: $(uptime)" >> "$LOG_FILE"
df -h / >> "$LOG_FILE" 2>&1

log "${GREEN}Update process completed successfully!${NC}"
log "Log saved to: $LOG_FILE"

# Display summary
echo -e "\n${GREEN}=== Update Summary ===${NC}"
echo "Date: $(date)"
echo "Log file: $LOG_FILE"
if [[ -f "$LOG_DIR/reboot-required" ]]; then
    echo -e "${YELLOW}⚠ System reboot recommended${NC}"
fi
echo -e "${GREEN}======================${NC}\n"

exit 0
