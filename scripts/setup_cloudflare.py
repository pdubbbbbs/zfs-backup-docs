#!/usr/bin/env python3
"""
Configure Cloudflare DNS for ZFS backup monitor
"""

import requests
import json
import sys
import os

# Configuration
ZONE_NAME = "42toluca.com"
RECORD_NAME = "backup-monitor.42toluca.com"
API_TOKEN = "io5xnkldGu6EhfV53Awn_MXjWDHAVP7iEDD1GezI"

def get_zone_id(api_token, zone_name):
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(
        "https://api.cloudflare.com/client/v4/zones",
        headers=headers
    )
    
    if response.status_code == 200:
        zones = response.json()["result"]
        for zone in zones:
            if zone["name"] == zone_name:
                return zone["id"]
    return None

def create_dns_record(api_token, zone_id, record_name):
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    # Get public IP
    ip_response = requests.get("https://api.ipify.org")
    if ip_response.status_code != 200:
        print("Error getting public IP address")
        return False
    
    public_ip = ip_response.text
    
    data = {
        "type": "A",
        "name": record_name,
        "content": public_ip,
        "proxied": True  # Enable Cloudflare proxy
    }
    
    response = requests.post(
        f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records",
        headers=headers,
        json=data
    )
    
    return response.status_code == 200

def main():
    print("Setting up Cloudflare DNS for backup monitor...")
    
    # Get zone ID
    zone_id = get_zone_id(API_TOKEN, ZONE_NAME)
    if not zone_id:
        print(f"Error: Could not find zone ID for {ZONE_NAME}")
        sys.exit(1)
    
    # Create DNS record
    if create_dns_record(API_TOKEN, zone_id, RECORD_NAME):
        print(f"\nDNS record created successfully!")
        print(f"Monitor will be available at: https://{RECORD_NAME}")
        
        # Create systemd service file
        service_content = f"""[Unit]
Description=ZFS Backup Web Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 {os.path.abspath('scripts/web_monitor.py')} --host 0.0.0.0 --port 8085
WorkingDirectory={os.path.abspath('scripts')}
User={os.getenv('USER')}
Restart=always

[Install]
WantedBy=multi-user.target
"""
        
        # Write service file
        with open('zfs-backup-monitor.service', 'w') as f:
            f.write(service_content)
        
        print("\nNext steps:")
        print("1. Install the systemd service:")
        print("   sudo mv zfs-backup-monitor.service /etc/systemd/system/")
        print("   sudo systemctl daemon-reload")
        print("   sudo systemctl enable zfs-backup-monitor")
        print("   sudo systemctl start zfs-backup-monitor")
        print("\n2. Configure your firewall to allow port 8085")
        print("\n3. Set up a reverse proxy (e.g., nginx) to forward traffic from 80/443 to 8085")
        
    else:
        print("Error creating DNS record")
        sys.exit(1)

if __name__ == "__main__":
    main()
