#!/bin/bash
# create_daily_backup.sh - Creates daily ZFS snapshots and backups
# Repository: https://github.com/pdubbbbbs/zfs-backup-docs

# Set script variables
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="${LOG_DIR}/daily_backup.log"
DATE=$(date '+%Y%m%d')
SNAPSHOT_NAME="daily-${DATE}"
BACKUP_DIR="/mnt/orico1/zfs_backups"
BACKUP_FILE="${BACKUP_DIR}/tank_stage-${SNAPSHOT_NAME}.gz"
CHECKSUM_FILE="${BACKUP_DIR}/tank_stage-${SNAPSHOT_NAME}.sha256"
TEMP_DIR="/tmp/zfs_backup"
EXIT_CODE=0

# Create log and temp directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$TEMP_DIR"

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

# Check if Orico1 is mounted
if ! mountpoint -q /mnt/orico1; then
    handle_error "Orico1 is not mounted. Aborting backup."
    exit 1
fi

# Create ZFS snapshot
log "Creating ZFS snapshot: tank/stage@${SNAPSHOT_NAME}"
if ! ssh root@192.168.12.34 "zfs snapshot tank/stage@${SNAPSHOT_NAME}"; then
    handle_error "Failed to create snapshot tank/stage@${SNAPSHOT_NAME}"
    exit 1
fi

# Export and compress ZFS snapshot
log "Exporting and compressing snapshot to ${BACKUP_FILE}"
if ! ssh root@192.168.12.34 "zfs send tank/stage@${SNAPSHOT_NAME}" | gzip -9 > "${BACKUP_FILE}"; then
    handle_error "Failed to export and compress snapshot"
    
    # Clean up failed snapshot
    log "Removing failed snapshot tank/stage@${SNAPSHOT_NAME}"
    ssh root@192.168.12.34 "zfs destroy tank/stage@${SNAPSHOT_NAME}"
    exit 1
fi

# Create SHA256 checksum
log "Creating SHA256 checksum file"
sha256sum "${BACKUP_FILE}" | awk '{print $1}' > "${CHECKSUM_FILE}"

# Verify backup integrity
log "Verifying backup integrity"
expected_checksum=$(cat "${CHECKSUM_FILE}")
actual_checksum=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')

if [ "$expected_checksum" != "$actual_checksum" ]; then
    handle_error "Checksum verification failed"
    exit 1
fi

log "Daily backup completed successfully: ${BACKUP_FILE}"
log "Backup size: $(du -h "${BACKUP_FILE}" | cut -f1)"

exit $EXIT_CODE

