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

# Configure VM
echo "Configuring VM..."
qm set ${TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${TEMPLATE_ID}-disk-0
qm set ${TEMPLATE_ID} --boot c --bootdisk scsi0
qm set ${TEMPLATE_ID} --ide2 ${STORAGE}:cloudinit
qm set ${TEMPLATE_ID} --serial0 socket --vga serial0
qm set ${TEMPLATE_ID} --agent enabled=1

# Resize disk (optional, adjust as needed)
qm resize ${TEMPLATE_ID} scsi0 20G

# Convert to template
echo "Converting to template..."
qm template ${TEMPLATE_ID}

# Clean up
rm -f /tmp/ubuntu-cloud.img

echo "✅ Template created successfully!"
echo "Template ID: ${TEMPLATE_ID}"
echo "Template Name: ${TEMPLATE_NAME}"
echo ""
echo "You can now use this template with Terraform by setting:"
echo "  vm_template_name = \"${TEMPLATE_NAME}\""
