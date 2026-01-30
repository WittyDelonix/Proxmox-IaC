#!/usr/bin/env python3
"""
Self-Healing Service for Proxmox Infrastructure
Receives webhooks from Alertmanager and automatically heals infrastructure issues
"""

from flask import Flask, request, jsonify
import requests
import logging
import os
import json
from datetime import datetime
from typing import Dict, List
import threading
import time

# Configuration
PROXMOX_API_URL = os.getenv('PROXMOX_API_URL', 'https://192.168.1.10:8006/api2/json')
PROXMOX_NODE = os.getenv('PROXMOX_NODE', 'pve')
PROXMOX_TOKEN_ID = os.getenv('PROXMOX_TOKEN_ID', '')
PROXMOX_TOKEN_SECRET = os.getenv('PROXMOX_TOKEN_SECRET', '')
WEBHOOK_PORT = int(os.getenv('WEBHOOK_PORT', '5000'))
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

# Flask app
app = Flask(__name__)

# Track restart history to prevent restart loops
restart_history: Dict[int, datetime] = {}


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


class SelfHealingService:
    """Main self-healing service"""
    
    def __init__(self):
        self.proxmox = ProxmoxAPI()
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
        instance = alert.get('labels', {}).get('instance', '')
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
        instance = alert.get('labels', {}).get('instance', '')
        logger.warning(f"High CPU usage detected: {instance}")
        
        if instance in self.vm_mapping:
            vmid = self.vm_mapping[instance]
            logger.info(f"High CPU on VM {vmid} - monitoring, manual intervention may be required")
            self.send_notification(f"High CPU alert on VM {vmid} ({instance})")
    
    def heal_high_memory(self, alert: Dict):
        """Heal high memory usage alert"""
        instance = alert.get('labels', {}).get('instance', '')
        logger.warning(f"High memory usage detected: {instance}")
        
        if instance in self.vm_mapping:
            vmid = self.vm_mapping[instance]
            logger.info(f"High memory on VM {vmid} - monitoring, may need resource adjustment")
            self.send_notification(f"High memory alert on VM {vmid} ({instance})")
    
    def send_notification(self, message: str):
        """Send notification"""
        logger.info(f"NOTIFICATION: {message}")
        try:
            with open('/var/log/self-healing-notifications.log', 'a') as f:
                f.write(f"{datetime.now().isoformat()} - {message}\n")
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
    
    def process_alert(self, alert: Dict):
        """Process a single alert"""
        alert_name = alert.get('labels', {}).get('alertname', '')
        status = alert.get('status', '')
        
        # Only process firing alerts
        if status != 'firing':
            logger.debug(f"Ignoring {status} alert: {alert_name}")
            return
        
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


# Global service instance
service = SelfHealingService()


@app.route('/webhook', methods=['POST'])
def webhook():
    """Receive alerts from Alertmanager"""
    try:
        data = request.get_json()
        
        if not data:
            logger.warning("Received empty webhook payload")
            return jsonify({'status': 'error', 'message': 'Empty payload'}), 400
        
        logger.info(f"Received webhook with {len(data.get('alerts', []))} alerts")
        
        # Process each alert
        for alert in data.get('alerts', []):
            service.process_alert(alert)
        
        return jsonify({'status': 'success', 'processed': len(data.get('alerts', []))}), 200
        
    except Exception as e:
        logger.error(f"Error processing webhook: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'self-healing',
        'vm_mapping_count': len(service.vm_mapping)
    }), 200


if __name__ == '__main__':
    # Disable SSL warnings for self-signed certificates
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    
    logger.info("Self-Healing Service starting")
    logger.info(f"Webhook listening on port: {WEBHOOK_PORT}")
    logger.info(f"Restart cooldown: {RESTART_COOLDOWN}s")
    logger.info(f"VM mappings loaded: {len(service.vm_mapping)}")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=WEBHOOK_PORT, debug=False)