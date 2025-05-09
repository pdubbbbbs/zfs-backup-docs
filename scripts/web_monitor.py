#!/usr/bin/env python3
"""
Web interface for ZFS backup monitoring
Repository: https://github.com/pdubbbbbs/zfs-backup-docs
"""

import os
import subprocess
import json
import datetime
import argparse
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import threading
import time
import socket

class BackupMonitor:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.html_dir = self.script_dir / "web"
        self.html_dir.mkdir(exist_ok=True)
        
    def get_backup_status(self):
        status = {
            "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "daily_backups": [],
            "weekly_backups": [],
            "monthly_backups": [],
            "storage": {},
            "system_health": {"status": "OK"}
        }
        
        # Check daily backups
        try:
            daily_files = list(Path("/mnt/orico1/zfs_backups").glob("tank_stage-daily-*.gz"))
            for file in sorted(daily_files, key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
                mtime = datetime.datetime.fromtimestamp(file.stat().st_mtime)
                age_days = (datetime.datetime.now() - mtime).days
                status["daily_backups"].append({
                    "file": file.name,
                    "date": mtime.strftime("%Y-%m-%d %H:%M:%S"),
                    "age_days": age_days,
                    "size": f"{file.stat().st_size / 1024 / 1024:.2f} MB"
                })
        except Exception as e:
            status["daily_backups"] = {"error": str(e)}

        # Check weekly backups
        try:
            weekly_files = list(Path("/mnt/orico1/zfs_backups").glob("tank_stage-weekly-*.gz"))
            for file in sorted(weekly_files, key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
                mtime = datetime.datetime.fromtimestamp(file.stat().st_mtime)
                age_days = (datetime.datetime.now() - mtime).days
                status["weekly_backups"].append({
                    "file": file.name,
                    "date": mtime.strftime("%Y-%m-%d %H:%M:%S"),
                    "age_days": age_days,
                    "size": f"{file.stat().st_size / 1024 / 1024:.2f} MB"
                })
        except Exception as e:
            status["weekly_backups"] = {"error": str(e)}

        # Check monthly backups
        try:
            monthly_files = list(Path("/mnt/orico2/zfs_backups").glob("tank_stage-monthly-*.gz"))
            for file in sorted(monthly_files, key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
                mtime = datetime.datetime.fromtimestamp(file.stat().st_mtime)
                age_days = (datetime.datetime.now() - mtime).days
                status["monthly_backups"].append({
                    "file": file.name,
                    "date": mtime.strftime("%Y-%m-%d %H:%M:%S"),
                    "age_days": age_days,
                    "size": f"{file.stat().st_size / 1024 / 1024:.2f} MB"
                })
        except Exception as e:
            status["monthly_backups"] = {"error": str(e)}

        # Check storage status
        try:
            df = subprocess.check_output(["df", "-h", "/mnt/orico1", "/mnt/orico2"]).decode()
            for line in df.split("\n")[1:]:
                if line:
                    parts = line.split()
                    status["storage"][parts[5]] = {
                        "total": parts[1],
                        "used": parts[2],
                        "available": parts[3],
                        "usage": parts[4]
                    }
        except Exception as e:
            status["storage"] = {"error": str(e)}

        return status

    def generate_html(self):
        status = self.get_backup_status()
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>ZFS Backup Monitor</title>
            <meta http-equiv="refresh" content="300">
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
                .container { max-width: 1200px; margin: 0 auto; }
                .card { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
                .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
                table { width: 100%; border-collapse: collapse; margin: 10px 0; }
                th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
                th { background: #f8f9fa; }
                .alert { color: red; }
                .ok { color: green; }
                .warning { color: orange; }
                .updated { font-size: 0.8em; color: #666; text-align: right; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>ZFS Backup Monitor</h1>
                    <p class="updated">Last updated: """ + status["timestamp"] + """</p>
                </div>
        """

        # Daily Backups
        html += """
                <div class="card">
                    <h2>Daily Backups</h2>
                    <table>
                        <tr>
                            <th>Backup File</th>
                            <th>Date</th>
                            <th>Age (days)</th>
                            <th>Size</th>
                            <th>Status</th>
                        </tr>
        """
        if isinstance(status["daily_backups"], dict) and "error" in status["daily_backups"]:
            html += f"""
                        <tr>
                            <td colspan="5" class="alert">Error: {status["daily_backups"]["error"]}</td>
                        </tr>
            """
        else:
            for backup in status["daily_backups"]:
                age_class = "ok" if backup["age_days"] <= 1 else "warning" if backup["age_days"] <= 2 else "alert"
                html += f"""
                            <tr>
                                <td>{backup['file']}</td>
                                <td>{backup['date']}</td>
                                <td class="{age_class}">{backup['age_days']}</td>
                                <td>{backup['size']}</td>
                                <td class="{age_class}">{'OK' if backup['age_days'] <= 1 else 'Warning' if backup['age_days'] <= 2 else 'Alert'}</td>
                            </tr>
                """
        html += """
                    </table>
                </div>
        """

        # Weekly Backups
        html += """
                <div class="card">
                    <h2>Weekly Backups</h2>
                    <table>
                        <tr>
                            <th>Backup File</th>
                            <th>Date</th>
                            <th>Age (days)</th>
                            <th>Size</th>
                            <th>Status</th>
                        </tr>
        """
        if isinstance(status["weekly_backups"], dict) and "error" in status["weekly_backups"]:
            html += f"""
                        <tr>
                            <td colspan="5" class="alert">Error: {status["weekly_backups"]["error"]}</td>
                        </tr>
            """
        else:
            for backup in status["weekly_backups"]:
                age_class = "ok" if backup["age_days"] <= 7 else "warning" if backup["age_days"] <= 14 else "alert"
                html += f"""
                            <tr>
                                <td>{backup['file']}</td>
                                <td>{backup['date']}</td>
                                <td class="{age_class}">{backup['age_days']}</td>
                                <td>{backup['size']}</td>
                                <td class="{age_class}">{'OK' if backup['age_days'] <= 7 else 'Warning' if backup['age_days'] <= 14 else 'Alert'}</td>
                            </tr>
                """
        html += """
                    </table>
                </div>
        """

        # Monthly Backups
        html += """
                <div class="card">
                    <h2>Monthly Backups</h2>
                    <table>
                        <tr>
                            <th>Backup File</th>
                            <th>Date</th>
                            <th>Age (days)</th>
                            <th>Size</th>
                            <th>Status</th>
                        </tr>
        """
        if isinstance(status["monthly_backups"], dict) and "error" in status["monthly_backups"]:
            html += f"""
                        <tr>
                            <td colspan="5" class="alert">Error: {status["monthly_backups"]["error"]}</td>
                        </tr>
            """
        else:
            for backup in status["monthly_backups"]:
                age_class = "ok" if backup["age_days"] <= 31 else "warning" if backup["age_days"] <= 45 else "alert"
                html += f"""
                            <tr>
                                <td>{backup['file']}</td>
                                <td>{backup['date']}</td>
                                <td class="{age_class}">{backup['age_days']}</td>
                                <td>{backup['size']}</td>
                                <td class="{age_class}">{'OK' if backup['age_days'] <= 31 else 'Warning' if backup['age_days'] <= 45 else 'Alert'}</td>
                            </tr>
                """
        html += """
                    </table>
                </div>
        """

        # Storage Status
        html += """
                <div class="card">
                    <h2>Storage Status</h2>
                    <table>
                        <tr>
                            <th>Mount Point</th>
                            <th>Total</th>
                            <th>Used</th>
                            <th>Available</th>
                            <th>Usage</th>
                        </tr>
        """
        if isinstance(status["storage"], dict) and "error" in status["storage"]:
            html += f"""
                        <tr>
                            <td colspan="5" class="alert">Error: {status["storage"]["error"]}</td>
                        </tr>
            """
        else:
            for mount, info in status["storage"].items():
                usage_value = int(info["usage"].strip('%'))
                usage_class = "ok" if usage_value < 80 else "warning" if usage_value < 90 else "alert"
                html += f"""
                            <tr>
                                <td>{mount}</td>
                                <td>{info['total']}</td>
                                <td>{info['used']}</td>
                                <td>{info['available']}</td>
                                <td class="{usage_class}">{info['usage']}</td>
                            </tr>
                """
        html += """
                    </table>
                </div>
            </div>
        </body>
        </html>
        """

        with open(self.html_dir / "index.html", "w") as f:
            f.write(html)

class MonitorHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(Path(__file__).parent / "web"), **kwargs)

def update_status(monitor):
    while True:
        monitor.generate_html()
        time.sleep(300)  # Update every 5 minutes

def find_available_port(start_port=8080, end_port=8090):
    for port in range(start_port, end_port + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('localhost', port))
                return port
            except OSError:
                continue
    raise OSError(f"No available ports in range {start_port}-{end_port}")

def main():
    parser = argparse.ArgumentParser(description='ZFS Backup Web Monitor')
    parser.add_argument('--port', type=int, help='Port to run the web server on (default: first available port 8080-8090)')
    parser.add_argument('--host', default='localhost', help='Host to bind to (default: localhost)')
    args = parser.parse_args()

    monitor = BackupMonitor()
    monitor.generate_html()
    
    # Start status update thread
    update_thread = threading.Thread(target=update_status, args=(monitor,), daemon=True)
    update_thread.start()
    
    # Find available port if none specified
    port = args.port if args.port else find_available_port()
    
    # Start web server
    server = HTTPServer((args.host, port), MonitorHandler)
    print(f"Server started at http://{args.host}:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
