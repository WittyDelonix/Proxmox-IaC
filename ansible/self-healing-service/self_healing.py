#!/usr/bin/env python3
"""
Self-Healing Service for Proxmox Infrastructure
Monitors Prometheus alerts and automatically heals infrastructure issues
"""

import requests
import time
import logging
import os
import json
from datetime import datetime
from typing import Dict, List
import subprocess

# Configuration
PROMETHEUS_URL = os.getenv('PROMETHEUS_URL', 'http://192.168.1.103:9090')
PROXMOX_API_URL = os.getenv('PROXMOX_API_URL', 'https://192.168.1.10:8006/api2/json')
PROXMOX_NODE = os.getenv('PROXMOX_NODE', 'pve')
PROXMOX_TOKEN_ID = os.getenv('PROXMOX_TOKEN_ID', '')
PROXMOX_TOKEN_SECRET = os.getenv('PROXMOX_TOKEN_SECRET', '')
CHECK_INTERVAL = int(os.getenv('CHECK_INTERVAL', '60'))  # seconds
RESTART_COOLDOWN = int(os.getenv('RESTART_COOLDOWN', '300'))  # 5 minutes

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/self-healing.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('SelfHealing')

# Track restart history to prevent restart loops
restart_history: Dict[str, datetime] = {}


class ProxmoxAPI:
    """Proxmox API client for VM management"""
    
    def __init__(self):
        self.base_url = PROXMOX_API_URL
        self.node = PROXMOX_NODE
        self.headers = {
            'Authorization': f'PVEAPIToken={PROXMOX_TOKEN_ID}={PROXMOX_TOKEN_SECRET}'
        }
        self.verify_ssl = False
    
    def get_vm_status(self, vmid: int) -> Dict:
        """Get VM status"""
        try:
            url = f"{self.base_url}/nodes/{self.node}/qemu/{vmid}/status/current"
            response = requests.get(url, headers=self.headers, verify=self.verify_ssl)
            response.raise_for_status()
            return response.json()['data']
        except Exception as e:
            logger.error(f"Error getting VM {vmid} status: {e}")
            return {}
    
    def start_vm(self, vmid: int) -> bool:
        """Start a VM"""
        try:
            url = f"{self.base_url}/nodes/{self.node}/qemu/{vmid}/status/start"
            response = requests.post(url, headers=self.headers, verify=self.verify_ssl)
            response.raise_for_status()
            logger.info(f"Successfully started VM {vmid}")
            return True
        except Exception as e:
            logger.error(f"Error starting VM {vmid}: {e}")
            return False
    
    def reboot_vm(self, vmid: int) -> bool:
        """Reboot a VM"""
        try:
            url = f"{self.base_url}/nodes/{self.node}/qemu/{vmid}/status/reboot"
            response = requests.post(url, headers=self.headers, verify=self.verify_ssl)
            response.raise_for_status()
            logger.info(f"Successfully rebooted VM {vmid}")
            return True
        except Exception as e:
            logger.error(f"Error rebooting VM {vmid}: {e}")
            return False


class PrometheusMonitor:
    """Monitor Prometheus for alerts"""
    
    def __init__(self):
        self.prometheus_url = PROMETHEUS_URL
    
    def get_active_alerts(self) -> List[Dict]:
        """Get active alerts from Prometheus"""
        try:
            url = f"{self.prometheus_url}/api/v1/alerts"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data['status'] == 'success':
                alerts = data['data']['alerts']
                # Filter only firing alerts
                active_alerts = [a for a in alerts if a['state'] == 'firing']
                return active_alerts
            return []
        except Exception as e:
            logger.error(f"Error fetching alerts from Prometheus: {e}")
            return []
    
    def query_metric(self, query: str):
        """Query Prometheus for metrics"""
        try:
            url = f"{self.prometheus_url}/api/v1/query"
            params = {'query': query}
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data['status'] == 'success':
                return data['data']['result']
            return []
        except Exception as e:
            logger.error(f"Error querying Prometheus: {e}")
            return []


class SelfHealingService:
    """Main self-healing service"""
    
    def __init__(self):
        self.proxmox = ProxmoxAPI()
        self.prometheus = PrometheusMonitor()
        self.vm_mapping = self.load_vm_mapping()
    
    def load_vm_mapping(self) -> Dict[str, int]:
        """Load instance to VM ID mapping from inventory"""
        mapping = {}
        try:
            with open('/opt/self-healing/vm_mapping.json', 'r') as f:
                mapping = json.load(f)
            logger.info(f"Loaded VM mapping: {mapping}")
        except FileNotFoundError:
            logger.warning("VM mapping file not found, using default mapping")
            # Default mapping - update based on your infrastructure
            mapping = {
                '192.168.1.100:9100': 100,
                '192.168.1.101:9100': 101,
                '192.168.1.102:9100': 102,
            }
        return mapping
    
    def can_restart_vm(self, vmid: int) -> bool:
        """Check if VM can be restarted based on cooldown period"""
        if vmid in restart_history:
            time_since_restart = (datetime.now() - restart_history[vmid]).total_seconds()
            if time_since_restart < RESTART_COOLDOWN:
                logger.info(f"VM {vmid} was restarted {time_since_restart}s ago, skipping (cooldown: {RESTART_COOLDOWN}s)")
                return False
        return True
    
    def heal_instance_down(self, alert: Dict):
        """Heal instance down alert"""
        instance = alert['labels'].get('instance', '')
        logger.warning(f"Instance down detected: {instance}")
        
        if instance in self.vm_mapping:
            vmid = self.vm_mapping[instance]
            
            if not self.can_restart_vm(vmid):
                return
            
            # Check VM status
            status = self.proxmox.get_vm_status(vmid)
            if status.get('status') == 'stopped':
                logger.info(f"VM {vmid} is stopped, attempting to start...")
                if self.proxmox.start_vm(vmid):
                    restart_history[vmid] = datetime.now()
                    self.send_notification(f"Auto-started VM {vmid} ({instance})")
            else:
                logger.warning(f"VM {vmid} appears to be running but not responding, may need manual intervention")
    
    def heal_high_cpu(self, alert: Dict):
        """Heal high CPU usage alert"""
        instance = alert['labels'].get('instance', '')
        logger.warning(f"High CPU usage detected: {instance}")
        
        if instance in self.vm_mapping:
            vmid = self.vm_mapping[instance]
            
            if not self.can_restart_vm(vmid):
                return
            
            # For high CPU, we might want to investigate before rebooting
            # This is a placeholder for more sophisticated handling
            logger.info(f"High CPU on VM {vmid} - monitoring, manual intervention may be required")
            self.send_notification(f"High CPU alert on VM {vmid} ({instance})")
    
    def heal_high_memory(self, alert: Dict):
        """Heal high memory usage alert"""
        instance = alert['labels'].get('instance', '')
        logger.warning(f"High memory usage detected: {instance}")
        
        if instance in self.vm_mapping:
            vmid = self.vm_mapping[instance]
            logger.info(f"High memory on VM {vmid} - monitoring, may need resource adjustment")
            self.send_notification(f"High memory alert on VM {vmid} ({instance})")
    
    def send_notification(self, message: str):
        """Send notification (placeholder for integration with notification systems)"""
        logger.info(f"NOTIFICATION: {message}")
        # Add integrations here: Slack, Email, PagerDuty, etc.
        try:
            # Example: Write to a notifications file
            with open('/var/log/self-healing-notifications.log', 'a') as f:
                f.write(f"{datetime.now().isoformat()} - {message}\n")
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
    
    def process_alerts(self):
        """Process all active alerts"""
        alerts = self.prometheus.get_active_alerts()
        
        if not alerts:
            logger.debug("No active alerts")
            return
        
        logger.info(f"Processing {len(alerts)} active alerts")
        
        for alert in alerts:
            alert_name = alert['labels'].get('alertname', '')
            
            try:
                if alert_name == 'InstanceDown':
                    self.heal_instance_down(alert)
                elif alert_name == 'HighCPUUsage':
                    self.heal_high_cpu(alert)
                elif alert_name == 'HighMemoryUsage':
                    self.heal_high_memory(alert)
                else:
                    logger.debug(f"No healing action for alert: {alert_name}")
            except Exception as e:
                logger.error(f"Error processing alert {alert_name}: {e}")
    
    def run(self):
        """Main service loop"""
        logger.info("Self-Healing Service started")
        logger.info(f"Monitoring Prometheus at: {PROMETHEUS_URL}")
        logger.info(f"Check interval: {CHECK_INTERVAL}s")
        logger.info(f"Restart cooldown: {RESTART_COOLDOWN}s")
        
        while True:
            try:
                self.process_alerts()
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
            
            time.sleep(CHECK_INTERVAL)


if __name__ == '__main__':
    # Disable SSL warnings for self-signed certificates
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    
    service = SelfHealingService()
    service.run()
