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

## Key Features

- ZFS snapshot-based backups (efficient, incremental)
- Dual storage for redundancy
- SHA256 checksums for file verification
- Detailed info files for monthly backups
- Gzip compression (level 9)

## License

This documentation is licensed under the [MIT License](LICENSE).

