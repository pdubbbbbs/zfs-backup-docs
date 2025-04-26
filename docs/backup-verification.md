# Backup Verification Procedures

This document outlines the procedures for verifying the integrity of ZFS backups.

## Verifying SHA256 Checksums

Each backup file has an associated SHA256 checksum file that can be used to verify the integrity of the backup.

### Manual Verification

To manually verify a backup file:

```bash
# For weekly backups
cd /mnt/orico1/zfs_backups
sha256sum -c tank_stage-weekly-YYYYWW.sha256

# For monthly backups
cd /mnt/orico2/zfs_backups
sha256sum -c tank_stage-monthly-YYYYMM.sha256
```

Example output for a valid backup:
```
/tmp/zfs_backup/tank_stage-monthly-202504.gz: OK
```

### Automated Verification Script

The repository includes a verification script (`scripts/verify_backups.sh`) that automates the verification process. To use it:

```bash
# Make sure the script is executable
chmod +x scripts/verify_backups.sh

# Run the verification
./scripts/verify_backups.sh
```

The script checks:
1. That the backup mounts are available
2. The integrity of all weekly backups
3. The integrity of all monthly backups
4. The existence of info files for monthly backups

## Examining Backup Info Files

Monthly backups include detailed `.info` files that contain information about the ZFS snapshot. Review these files to ensure:

1. The backup was created at the expected time
2. The source dataset is correct
3. The snapshot properties look reasonable

## Performing Test Restores

To fully verify a backup, performing a test restore is recommended:

1. Create a temporary location to restore the backup
2. Decompress the backup file
3. Import the ZFS snapshot
4. Verify the data integrity

```bash
# Example restore procedure (run on Proxmox server)
mkdir -p /tmp/restore_test
cp /mnt/orico2/zfs_backups/tank_stage-monthly-202504.gz /tmp/restore_test/
cd /tmp/restore_test
gunzip tank_stage-monthly-202504.gz
zfs receive tank/test_restore < tank_stage-monthly-202504
```

## Monitoring Backup Age

Regularly check the age of backup files to ensure the backup process is running as expected:

```bash
# Check age of latest backups
find /mnt/orico1/zfs_backups -type f -name "*.gz" -exec ls -la {} \;
find /mnt/orico2/zfs_backups -type f -name "*.gz" -exec ls -la {} \;
```

## Troubleshooting

If verification fails:

1. Check if the backup file is corrupted or incomplete
2. Verify that the checksums match
3. Check disk space on Orico drives
4. Review Proxmox server logs for backup errors
5. Ensure the CIFS mounts are working correctly

