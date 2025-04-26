# ZFS Backup System Documentation

This repository contains documentation for the ZFS backup system used to create and manage backups from the Proxmox server to Orico external drives.

## System Overview

The backup system performs regular ZFS snapshots of the `tank/stage` dataset on the Proxmox server (192.168.112.34), creates compressed exports, and stores them on two Orico drives mounted via CIFS.

### Backup Types

- **Weekly Backups**: Stored in `/mnt/orico1/zfs_backups/`
  - Naming pattern: `tank_stage-weekly-YYYYWW.gz`
  - Example: `tank_stage-weekly-202517.gz` (Week 17 of 2025)
  
- **Monthly Backups**: Stored in `/mnt/orico2/zfs_backups/`
  - Naming pattern: `tank_stage-monthly-YYYYMM.gz`
  - Example: `tank_stage-monthly-202504.gz` (April 2025)

### System Architecture

```
Proxmox Server (192.168.112.34)
└── ZFS Pool: tank
    └── Dataset: tank/stage
        ├── Snapshot: @weekly-YYYYWW
        └── Snapshot: @monthly-YYYYMM
            │
            ▼
    [Backup Processing]
    └── Temporary files in /tmp/zfs_backup/
        │
        ▼
NAS Server (192.168.12.168)
├── Orico1 Share
│   └── /zfs_backups/
│       ├── tank_stage-weekly-YYYYWW.gz
│       └── tank_stage-weekly-YYYYWW.sha256
│
└── Orico2 Share
    └── /zfs_backups/
        ├── tank_stage-monthly-YYYYMM.gz
        ├── tank_stage-monthly-YYYYMM.info
        └── tank_stage-monthly-YYYYMM.sha256
```

## Documentation Contents

- **Configuration**: [Configuration details](docs/configuration.md)
- **Verification**: [Backup verification procedures](docs/backup-verification.md)
- **Info Files**: [Example backup info file](docs/backup-info-example.md)
- **Scripts**: Utility scripts for managing and verifying backups

## Utility Scripts

This repository includes several utility scripts for managing, monitoring, and verifying the backup system:

### verify_backups.sh

Verifies the integrity of all weekly and monthly backups using SHA256 checksums.

**Usage:**
```bash
./scripts/verify_backups.sh
```

**Features:**
- Checks backup mount points availability
- Verifies weekly backup integrity
- Verifies monthly backup integrity
- Checks for the presence of info files
- Provides a summary of verification results

### email_report.sh

Generates and emails a comprehensive backup status report.

**Usage:**
```bash
./scripts/email_report.sh
```

**Features:**
- Checks backup freshness and availability
- Includes storage usage information
- Runs verification and includes results
- Emails the report to specified recipients
- Maintains logs of email operations

### monitor_backups.sh

Monitors backup freshness, integrity, and system health, sending alerts on issues.

**Usage:**
```bash
./scripts/monitor_backups.sh
```

**Features:**
- Checks mount point availability
- Verifies backup freshness (age thresholds)
- Monitors storage space usage
- Runs integrity verification
- Sends alerts on issues to specified email address

### maintenance.sh

Performs routine maintenance tasks on the backup system.

**Usage:**
```bash
./scripts/maintenance.sh
```

**Features:**
- Rotates old backups (keeping configurable number)
- Cleans up old log files
- Checks system health (disk space, memory, load)
- Verifies mount integrity with write tests
- Automatically adds verification to crontab if needed

## Setting Up Automated Monitoring

To automate the monitoring and maintenance, add the scripts to your crontab:

```bash
# Run verification daily at 1 AM
0 1 * * * /path/to/scripts/verify_backups.sh

# Send email reports at 7 AM
0 7 * * * /path/to/scripts/email_report.sh

# Run monitoring every 4 hours
0 */4 * * * /path/to/scripts/monitor_backups.sh

# Run maintenance weekly on Sunday at 2 AM
0 2 * * 0 /path/to/scripts/maintenance.sh
```

## Key Features

- ZFS snapshot-based backups (efficient, incremental)
- Dual storage for redundancy
- SHA256 checksums for file verification
- Detailed info files for monthly backups
- Gzip compression (level 9)
- Automated monitoring and reporting
- System health checks and maintenance

## License

This documentation is licensed under the [MIT License](LICENSE).

