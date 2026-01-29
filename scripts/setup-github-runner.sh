#!/bin/bash
#
# Script to setup GitHub self-hosted runner on local machine
#

set -e

echo "GitHub Self-Hosted Runner Setup"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Please do not run this script as root"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl jq git

# Create runner directory
RUNNER_DIR="$HOME/actions-runner"
mkdir -p $RUNNER_DIR
cd $RUNNER_DIR

# Download latest runner
echo "Downloading GitHub Actions Runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract runner
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo ""
echo "✅ Runner downloaded successfully!"
echo ""
echo "Next steps:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to: Settings > Actions > Runners > New self-hosted runner"
echo "3. Copy the configuration command and run it in: $RUNNER_DIR"
echo ""
echo "Example configuration command:"
echo "./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN"
echo ""
echo "After configuration, install as service:"
echo "sudo ./svc.sh install"
echo "sudo ./svc.sh start"
echo ""
echo "Required software on runner machine:"
echo "  - Terraform (will be installed by GitHub Actions)"
echo "  - Python3 + pip"
echo "  - Ansible (will be installed by GitHub Actions)"
echo "  - SSH access to Proxmox VMs"
echo ""

# Install required software
echo "Installing required software on runner machine..."
sudo apt-get install -y python3 python3-pip wget unzip

# Install Terraform
TERRAFORM_VERSION="1.6.0"
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform ${TERRAFORM_VERSION}..."
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    echo "✅ Terraform installed"
else
    echo "✅ Terraform already installed"
fi

# Verify installations
echo ""
echo "Verifying installations..."
terraform --version
python3 --version

echo ""
echo "✅ Setup complete!"
