#!/bin/bash
# maintenance.sh - Routine maintenance tasks for ZFS backup system
# Repository: https://github.com/pdubbbbbs/zfs-backup-docs

# Set script variables
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="${LOG_DIR}/maintenance.log"
WEEKLY_RETAIN=8      # Number of weekly backups to keep
MONTHLY_RETAIN=12    # Number of monthly backups to keep
EXIT_CODE=0

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    local message="$1"
    log "ERROR: $message"
    EXIT_CODE=1
}

# Rotate old backups
rotate_backups() {
    log "Starting backup rotation..."
    
    # Rotate weekly backups
    log "Rotating weekly backups (keeping last $WEEKLY_RETAIN)..."
    local weekly_count=$(find /mnt/orico1/zfs_backups -name "tank_stage-weekly-*.gz" | wc -l)
    if [ $weekly_count -gt $WEEKLY_RETAIN ]; then
        find /mnt/orico1/zfs_backups -name "tank_stage-weekly-*.gz" -type f -printf '%T@ %p\n' | \
        sort -n | head -n $(($weekly_count - $WEEKLY_RETAIN)) | while read -r line; do
            file=$(echo "$line" | cut -d' ' -f2-)
            log "Removing old weekly backup: $(basename "$file")"
            rm "$file" "${file%.gz}.sha256"
        done
    fi
    
    # Rotate monthly backups
    log "Rotating monthly backups (keeping last $MONTHLY_RETAIN)..."
    local monthly_count=$(find /mnt/orico2/zfs_backups -name "tank_stage-monthly-*.gz" | wc -l)
    if [ $monthly_count -gt $MONTHLY_RETAIN ]; then
        find /mnt/orico2/zfs_backups -name "tank_stage-monthly-*.gz" -type f -printf '%T@ %p\n' | \
        sort -n | head -n $(($monthly_count - $MONTHLY_RETAIN)) | while read -r line; do
            file=$(echo "$line" | cut -d' ' -f2-)
            log "Removing old monthly backup: $(basename "$file")"
            rm "$file" "${file%.gz}.sha256" "${file%.gz}.info"
        done
    fi
}

# Clean up old logs
cleanup_logs() {
    log "Cleaning up old logs..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete
    find "$LOG_DIR" -name "backup_report_*.txt" -type f -mtime +30 -delete
}

# Check system health
check_system_health() {
    log "Checking system health..."
    
    # Check system disk space
    local root_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$root_usage" -gt 90 ]; then
        handle_error "System root partition usage is ${root_usage}% (warning threshold: 90%)"
    fi
    
    # Check system memory
    local free_mem=$(free -m | awk 'NR==2 {print $4}')
    if [ "$free_mem" -lt 512 ]; then
        handle_error "Low system memory: ${free_mem}MB free"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | tr -d ' ')
    if [ "$(echo "$load_avg > 4" | bc)" -eq 1 ]; then
        handle_error "High system load: $load_avg"
    fi
}

# Verify mount integrity
verify_mounts() {
    log "Verifying mount integrity..."
    
    # Test write access to Orico drives
    for mount in /mnt/orico1/zfs_backups /mnt/orico2/zfs_backups; do
        if ! touch "$mount/.test_write" 2>/dev/null; then
            handle_error "Cannot write to $mount"
        else
            rm "$mount/.test_write"
            log "Write test successful for $mount"
        fi
    done
}

# Main execution
log "Starting maintenance tasks"

# Perform all maintenance tasks
rotate_backups
cleanup_logs
check_system_health
verify_mounts

# Generate maintenance summary
if [ $EXIT_CODE -eq 0 ]; then
    log "All maintenance tasks completed successfully"
else
    log "Maintenance completed with errors (exit code: $EXIT_CODE)"
fi

# Schedule next verification
if ! crontab -l | grep -q "verify_backups.sh"; then
    (crontab -l 2>/dev/null; echo "0 1 * * * $(dirname "$0")/verify_backups.sh") | crontab -
    log "Added verification script to crontab"
fi

exit $EXIT_CODE
