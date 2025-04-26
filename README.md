# ZFS Backup System Documentation

This repository contains documentation for the ZFS backup system used to create and manage backups from the Proxmox server to Orico external drives.

## System Overview

The backup system performs regular ZFS snapshots of the `tank/stage` dataset on the Proxmox server (192.168.112.34), creates compressed exports, and stores them on two Orico drives mounted via CIFS.

### Backup Types

- **Daily Backups**: Stored in `/mnt/orico1/zfs_backups/`
  - Naming pattern: `tank_stage-daily-YYYYMMDD.gz`
  - Example: `tank_stage-daily-20250426.gz` (April 26, 2025)
  - Retention: 7 days

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
        ├── Snapshot: @daily-YYYYMMDD
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
│       ├── tank_stage-daily-YYYYMMDD.gz
│       ├── tank_stage-daily-YYYYMMDD.sha256
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


## ZFS Backup Monitor

The ZFS Backup Monitor provides a web-based interface for monitoring the status of your ZFS backup system.

### Overview

The monitoring system continuously tracks the status of your daily, weekly, and monthly ZFS backups, providing an easy-to-read dashboard with status indicators. The monitor automatically refreshes every 5 minutes to show the latest status of your backup system.

### Features

- **Comprehensive Backup Monitoring**:
  - Daily backup status and age tracking
  - Weekly backup status and age tracking
  - Monthly backup status and age tracking
  - Color-coded status indicators for quick assessment
  
- **Storage Status Monitoring**:
  - Disk space usage for all backup drives
  - Visual indicators for storage capacity issues
  
- **User-Friendly Interface**:
  - Clean, responsive web interface
  - Automatic page refresh every 5 minutes
  - Compatible with desktop and mobile browsers
  
- **Status Thresholds**:
  - Daily backups: 
    - OK (green): ≤ 1 day old
    - Warning (orange): 1-2 days old
    - Alert (red): > 2 days old
  - Weekly backups:
    - OK (green): ≤ 7 days old
    - Warning (orange): 7-14 days old
    - Alert (red): > 14 days old
  - Monthly backups:
    - OK (green): ≤ 31 days old 
    - Warning (orange): 31-45 days old
    - Alert (red): > 45 days old

### Installation

Follow these steps to install and configure the ZFS Backup Monitor:

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone https://github.com/pdubbbbbs/zfs-backup-docs.git
   cd zfs-backup-docs
   ```

2. **Install the systemd service file**:
   ```bash
   sudo cp zfs-backup-monitor.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

3. **Configure the service** (optional):
   
   Edit the service file if you need to change default settings:
   ```bash
   sudo nano /etc/systemd/system/zfs-backup-monitor.service
   ```
   
   You can modify port, host, and other parameters in the ExecStart line.

4. **Enable and start the service**:
   ```bash
   sudo systemctl enable zfs-backup-monitor
   sudo systemctl start zfs-backup-monitor
   ```

### Usage

#### Accessing the Web Interface

Once the service is running, you can access the web interface at:
```
http://your-server-ip:8080
```

If you're accessing it locally on the same machine:
```
http://localhost:8080
```

#### Understanding Status Indicators

The monitor uses a color-coded system to indicate backup status:

- **Green (OK)**: The backup is recent and within expected time frames
- **Orange (Warning)**: The backup is older than ideal but still acceptable
- **Red (Alert)**: The backup is too old and requires attention

#### Service Management

Common commands for managing the ZFS Backup Monitor service:

- **Check service status**:
  ```bash
  sudo systemctl status zfs-backup-monitor
  ```

- **Start the service**:
  ```bash
  sudo systemctl start zfs-backup-monitor
  ```

- **Stop the service**:
  ```bash
  sudo systemctl stop zfs-backup-monitor
  ```

- **Restart the service**:
  ```bash
  sudo systemctl restart zfs-backup-monitor
  ```

- **View service logs**:
  ```bash
  sudo journalctl -u zfs-backup-monitor
  ```
  
  To see the most recent logs:
  ```bash
  sudo journalctl -u zfs-backup-monitor -n 50 --no-pager
  ```

- **Follow logs in real-time**:
  ```bash
  sudo journalctl -u zfs-backup-monitor -f
  ```

### Troubleshooting

Here are some common issues and their solutions:

1. **Web interface not accessible**:
   - Check if the service is running: `sudo systemctl status zfs-backup-monitor`
   - Verify firewall settings allow access to port 8080
   - Check logs for specific errors: `sudo journalctl -u zfs-backup-monitor -n 100`

2. **Missing backup information**:
   - Verify that backup directories are properly mounted
   - Check file permissions for the backup directories
   - Run `ls -la /mnt/orico1/zfs_backups/` and `ls -la /mnt/orico2/zfs_backups/` to confirm access

3. **Service won't start**:
   - Check for syntax errors in the service file
   - Verify Python 3 is installed and in the expected location
   - Ensure user permissions are correct
   - Look for detailed error messages in the logs

4. **Error: "Address already in use"**:
   - Another service is using port 8080
   - Modify the `--port` parameter in the service file to use a different port

5. **Data shows as "Error"**:
   - Check mount points for the external drives
   - Verify the service user has access permissions to the backup directories
   - Check system logs for drive/mount related errors

### Manual Execution

If you want to run the monitor manually for testing:

```bash
cd /home/sitboo/zfs-backup-docs
python3 scripts/web_monitor.py
```

Or with custom parameters:

```bash
python3 scripts/web_monitor.py --host=0.0.0.0 --port=8888
```

This will start the web server in the foreground. Press Ctrl+C to stop it.
