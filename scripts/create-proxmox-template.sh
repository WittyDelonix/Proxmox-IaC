#!/bin/bash
#
# Script to create Ubuntu Cloud-Init template in Proxmox
# Run this on your Proxmox host
#

set -e

# Configuration
TEMPLATE_ID=9000
TEMPLATE_NAME="ubuntu-cloud-template"
STORAGE="local-lvm"
UBUNTU_VERSION="22.04"
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"

echo "Creating Ubuntu Cloud-Init Template..."

# Download Ubuntu Cloud Image
echo "Downloading Ubuntu Cloud Image..."
wget -O /tmp/ubuntu-cloud.img "${UBUNTU_IMAGE_URL}"

# Create VM
echo "Creating VM ${TEMPLATE_ID}..."
qm create ${TEMPLATE_ID} --name ${TEMPLATE_NAME} --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
echo "Importing disk..."
qm importdisk ${TEMPLATE_ID} /tmp/ubuntu-cloud.img ${STORAGE}

# Configure VM with PROPER BOOT ORDER
echo "Configuring VM..."
qm set ${TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${TEMPLATE_ID}-disk-0

# CRITICAL: Set boot order to scsi0
echo "Setting boot order (CRITICAL)..."
qm set ${TEMPLATE_ID} --boot order=scsi0

# Add cloud-init drive
echo "Adding cloud-init drive..."
qm set ${TEMPLATE_ID} --ide2 ${STORAGE}:cloudinit

# Enable QEMU agent
echo "Enabling QEMU agent..."
qm set ${TEMPLATE_ID} --agent enabled=1

# Set serial console
echo "Configuring serial console..."
qm set ${TEMPLATE_ID} --serial0 socket --vga serial0

# Resize disk (optional, adjust as needed)
echo "Resizing disk to 20GB..."
qm resize ${TEMPLATE_ID} scsi0 20G

# Verify configuration before templating
echo ""
echo "Verifying configuration..."
qm config ${TEMPLATE_ID} | grep -E "boot|scsi0|ide2|agent"

# Convert to template
echo ""
echo "Converting to template..."
qm template ${TEMPLATE_ID}

# Clean up
rm -f /tmp/ubuntu-cloud.img

echo ""
echo "✅ Template created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Template ID:   ${TEMPLATE_ID}"
echo "Template Name: ${TEMPLATE_NAME}"
echo ""
echo "Configuration:"
echo "  • Boot Order:  scsi0 (PRIMARY - CRITICAL FOR BOOT)"
echo "  • Main Disk:   scsi0 on ${STORAGE}"
echo "  • Cloud-Init:  ide2 on ${STORAGE}"
echo "  • QEMU Agent:  Enabled"
echo "  • Disk Size:   20GB"
echo ""
echo "You can now use this template with Terraform by setting:"
echo "  vm_template_name = \"${TEMPLATE_NAME}\""
echo ""
echo "⚠️  IMPORTANT: Test the template before using in production:"
echo "  1. Clone a test VM: qm clone ${TEMPLATE_ID} 999 --name test-vm"
echo "  2. Start it: qm start 999"
echo "  3. Check console: qm terminal 999"
echo "  4. Should boot successfully"
echo "  5. Delete test VM: qm destroy 999"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
