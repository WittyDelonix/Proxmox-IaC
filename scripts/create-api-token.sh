#!/bin/bash
#
# Script to create Proxmox API token for Terraform
# Run this on your Proxmox host
#

set -e

echo "Creating Proxmox API Token for Terraform..."
echo ""

# Create user
pveum user add terraform@pam --comment "Terraform automation user"

# Create role with necessary permissions
pveum role add TerraformRole -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

# Add role to user
pveum aclmod / -user terraform@pam -role TerraformRole

# Create API token
pveum user token add terraform@pam terraform --privsep 0

echo ""
echo "✅ API token created successfully!"
echo ""
echo "⚠️  IMPORTANT: Save the token information shown above!"
echo "You will need to add these to your GitHub Secrets:"
echo ""
echo "PROXMOX_API_TOKEN_ID: terraform@pam!terraform"
echo "PROXMOX_API_TOKEN_SECRET: <token value from above>"
echo ""
