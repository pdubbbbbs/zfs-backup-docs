#!/bin/bash
# email_report.sh - Daily backup verification report script
# Repository: https://github.com/pdubbbbbs/zfs-backup-docs

# Set script variables
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="${LOG_DIR}/email_report.log"
DATE=$(date '+%Y-%m-%d')
REPORT_FILE="${LOG_DIR}/backup_report_${DATE}.txt"
EMAIL_TO="sitboo@42toluca.com"  # Change this to your email

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Run verification and generate report
generate_report() {
    {
        echo "ZFS Backup Verification Report - ${DATE}"
        echo "======================================="
        echo
        echo "1. Backup Status"
        echo "---------------"
        
        # Check weekly backups
        WEEKLY_FILE=$(find /mnt/orico1/zfs_backups -name "tank_stage-weekly-*.gz" -type f -mtime -7 | sort -n | tail -n1)
        if [ -n "$WEEKLY_FILE" ]; then
            echo "Weekly backup found: $(basename "$WEEKLY_FILE")"
            echo "Age: $(find "$WEEKLY_FILE" -printf "%Ad days\n")"
        else
            echo "WARNING: No recent weekly backup found!"
        fi

        # Check monthly backups
        MONTHLY_FILE=$(find /mnt/orico2/zfs_backups -name "tank_stage-monthly-*.gz" -type f -mtime -31 | sort -n | tail -n1)
        if [ -n "$MONTHLY_FILE" ]; then
            echo "Monthly backup found: $(basename "$MONTHLY_FILE")"
            echo "Age: $(find "$MONTHLY_FILE" -printf "%Ad days\n")"
        else
            echo "WARNING: No recent monthly backup found!"
        fi

        echo
        echo "2. Storage Status"
        echo "----------------"
        df -h /mnt/orico1 /mnt/orico2

        echo
        echo "3. Verification Results"
        echo "---------------------"
        # Run verification script and capture output
        "$(dirname "$0")/verify_backups.sh"

    } > "$REPORT_FILE"
}

# Send email function
send_email() {
    if command -v mail >/dev/null 2>&1; then
        mail -s "ZFS Backup Report - ${DATE}" "$EMAIL_TO" < "$REPORT_FILE"
        log "Email sent to $EMAIL_TO"
    else
        log "ERROR: 'mail' command not found. Please install mailutils."
        exit 1
    fi
}

# Main execution
log "Starting backup report generation"
generate_report
log "Report generated at $REPORT_FILE"
send_email
log "Email report process completed"
