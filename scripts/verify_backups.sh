#!/bin/bash
# Script to verify the integrity of ZFS backups using SHA256 checksums

# Set script to exit on error
set -e

echo "=== ZFS Backup Verification Tool ==="
echo "Checking backup mounts..."

# Check if mounts are available
if [ ! -d "/mnt/orico1/zfs_backups" ] || [ ! -d "/mnt/orico2/zfs_backups" ]; then
  echo "ERROR: Backup mounts not found. Ensure Orico drives are mounted."
  exit 1
fi

verification_summary() {
  echo -e "\nSummary:"
  echo "Weekly backups verified: $weekly_count"
  echo "Monthly backups verified: $monthly_count"
  
  if [ $weekly_count -eq 0 ] && [ $monthly_count -eq 0 ]; then
    echo "No backups were verified. Please check if backup files exist."
    exit 1
  fi
}

# Verify weekly backups
echo -e "\nVerifying weekly backups in /mnt/orico1/zfs_backups..."
cd /mnt/orico1/zfs_backups || exit 1
weekly_count=0

for checksum_file in *.sha256; do
  if [ -f "$checksum_file" ]; then
    echo "Checking: $checksum_file"
    backup_file="${checksum_file%.sha256}.gz"
    
    if [ ! -f "$backup_file" ]; then
      echo "  ERROR: Backup file $backup_file not found!"
      continue
    fi
    
    expected_checksum=$(cat "$checksum_file" | awk '{print $1}')
    actual_checksum=$(sha256sum "$backup_file" | awk '{print $1}')
    
    if [ "$expected_checksum" = "$actual_checksum" ]; then
      echo "  ✓ Verified: $backup_file"
      weekly_count=$((weekly_count+1))
    else
      echo "  ✗ FAILED: Checksum mismatch for $backup_file"
      echo "    Expected: $expected_checksum"
      echo "    Actual:   $actual_checksum"
    fi
  fi
done

# Verify monthly backups
echo -e "\nVerifying monthly backups in /mnt/orico2/zfs_backups..."
cd /mnt/orico2/zfs_backups || exit 1
monthly_count=0

for checksum_file in *.sha256; do
  if [ -f "$checksum_file" ]; then
    echo "Checking: $checksum_file"
    backup_file="${checksum_file%.sha256}.gz"
    
    if [ ! -f "$backup_file" ]; then
      echo "  ERROR: Backup file $backup_file not found!"
      continue
    fi
    
    expected_checksum=$(cat "$checksum_file" | awk '{print $1}')
    actual_checksum=$(sha256sum "$backup_file" | awk '{print $1}')
    
    if [ "$expected_checksum" = "$actual_checksum" ]; then
      echo "  ✓ Verified: $backup_file"
      monthly_count=$((monthly_count+1))
      
      # Check if info file exists
      info_file="${checksum_file%.sha256}.info"
      if [ -f "$info_file" ]; then
        echo "  ℹ Info file available: $info_file"
      else
        echo "  ⚠ WARNING: Info file not found for $backup_file"
      fi
    else
      echo "  ✗ FAILED: Checksum mismatch for $backup_file"
      echo "    Expected: $expected_checksum"
      echo "    Actual:   $actual_checksum"
    fi
  fi
done

verification_summary
