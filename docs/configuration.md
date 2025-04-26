# Backup System Configuration

This document outlines the configuration of the ZFS backup system.

## Storage Configuration

### Source System

- **Proxmox Server**: 192.168.112.34
- **Source Dataset**: `tank/stage`
- **Snapshot Naming**:
  - Weekly: `@weekly-YYYYWW`
  - Monthly: `@monthly-YYYYMM`

### Destination Storage

- **NAS Server**: 192.168.12.168
- **Mount Points**:
  - Weekly backups: `/mnt/orico1/zfs_backups/`
  - Monthly backups: `/mnt/orico2/zfs_backups/`

### CIFS Mount Configuration

The Orico drives are mounted on the client system via CIFS. Here's the fstab configuration:

```
//192.168.12.168/Orico1 /mnt/orico1 cifs credentials=/root/.smbcredentials,vers=2.1,sec=ntlmv2,iocharset=utf8,uid=1000,gid=1000 0 0
//192.168.12.168/Orico2 /mnt/orico2 cifs credentials=/root/.smbcredentials,vers=2.1,sec=ntlmv2,iocharset=utf8,uid=1000,gid=1000 0 0
```

## Backup Process

1. ZFS snapshot is created on the Proxmox server
2. Snapshot is exported and compressed with gzip (level 9)
3. SHA256 checksums are generated for verification
4. Files are transferred to the Orico drives
5. Info files are generated for monthly backups

## File Structure

### Weekly Backup Files

- **Primary Backup**: `tank_stage-weekly-YYYYWW.gz`
- **Checksum File**: `tank_stage-weekly-YYYYWW.sha256`

### Monthly Backup Files

- **Primary Backup**: `tank_stage-monthly-YYYYMM.gz`
- **Checksum File**: `tank_stage-monthly-YYYYMM.sha256`
- **Info File**: `tank_stage-monthly-YYYYMM.info`

## Accessing Proxmox Configuration

To access the full configuration on the Proxmox server (192.168.112.34), you should:

1. Connect to the Proxmox web interface at `https://192.168.112.34:8006`
2. Navigate to Datacenter → Storage to view the ZFS configuration
3. Check system tasks and scheduled jobs for backup scheduling

