#!/bin/bash
# monitor_backups.sh - Monitor backup freshness and integrity
# Repository: https://github.com/pdubbbbbs/zfs-backup-docs

# Set script variables
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="${LOG_DIR}/monitor.log"
ALERT_EMAIL="sitboo@42toluca.com"  # Change this to your email
WEEKLY_MAX_AGE=8     # Days
MONTHLY_MAX_AGE=32   # Days
EXIT_CODE=0

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"
    echo "$message" | mail -s "ZFS Backup Alert" "$ALERT_EMAIL"
    EXIT_CODE=1
}

# Check mount points
check_mounts() {
    log "Checking mount points..."
    
    if ! mountpoint -q /mnt/orico1; then
        alert "Orico1 is not mounted!"
    fi
    
    if ! mountpoint -q /mnt/orico2; then
        alert "Orico2 is not mounted!"
    fi
}

# Check backup freshness
check_freshness() {
    log "Checking backup freshness..."
    
    # Check weekly backups
    local newest_weekly=$(find /mnt/orico1/zfs_backups -name "tank_stage-weekly-*.gz" -type f -printf '%T@ %p\n' | sort -n | tail -n1)
    if [ -n "$newest_weekly" ]; then
        local weekly_age=$(( ($(date +%s) - $(echo "$newest_weekly" | cut -d' ' -f1)) / 86400 ))
        if [ $weekly_age -gt $WEEKLY_MAX_AGE ]; then
            alert "Weekly backup is $weekly_age days old (max age: $WEEKLY_MAX_AGE days)"
        else
            log "Weekly backup is $weekly_age days old (OK)"
        fi
    else
        alert "No weekly backups found!"
    fi
    
    # Check monthly backups
    local newest_monthly=$(find /mnt/orico2/zfs_backups -name "tank_stage-monthly-*.gz" -type f -printf '%T@ %p\n' | sort -n | tail -n1)
    if [ -n "$newest_monthly" ]; then
        local monthly_age=$(( ($(date +%s) - $(echo "$newest_monthly" | cut -d' ' -f1)) / 86400 ))
        if [ $monthly_age -gt $MONTHLY_MAX_AGE ]; then
            alert "Monthly backup is $monthly_age days old (max age: $MONTHLY_MAX_AGE days)"
        else
            log "Monthly backup is $monthly_age days old (OK)"
        fi
    else
        alert "No monthly backups found!"
    fi
}

# Check storage space
check_storage() {
    log "Checking storage space..."
    
    # Check Orico1
    local orico1_usage=$(df -h /mnt/orico1 | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$orico1_usage" -gt 90 ]; then
        alert "Orico1 storage usage is ${orico1_usage}% (warning threshold: 90%)"
    fi
    
    # Check Orico2
    local orico2_usage=$(df -h /mnt/orico2 | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$orico2_usage" -gt 90 ]; then
        alert "Orico2 storage usage is ${orico2_usage}% (warning threshold: 90%)"
    fi
}

# Run verification script
verify_backups() {
    log "Running backup verification..."
    if ! "$(dirname "$0")/verify_backups.sh"; then
        alert "Backup verification failed! Check verify_backups.sh output for details."
    fi
}

# Main execution
log "Starting backup monitoring"
check_mounts
check_freshness
check_storage
verify_backups
log "Monitoring completed with exit code $EXIT_CODE"

exit $EXIT_CODE
