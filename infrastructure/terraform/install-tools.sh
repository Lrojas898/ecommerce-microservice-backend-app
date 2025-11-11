#!/bin/bash

# ============================================================
# Install Tools Script for Terraform Infrastructure
# ============================================================
# This script installs Terraform, kubectl, and doctl
# ============================================================

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Installing Infrastructure Tools                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Detect OS
OS="$(uname -s)"
echo "🖥️  Detected OS: $OS"
echo ""

# ============================================================
# Install Terraform
# ============================================================

echo "📦 Installing Terraform..."

if command -v terraform &> /dev/null; then
    echo "✅ Terraform already installed: $(terraform version | head -1)"
else
    case "$OS" in
        Linux*)
            # Install for Linux
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install terraform
            ;;
        Darwin*)
            # Install for macOS
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
            ;;
        *)
            echo "❌ Unsupported OS for auto-install. Please install manually:"
            echo "   https://www.terraform.io/downloads"
            ;;
    esac
    echo "✅ Terraform installed: $(terraform version | head -1)"
fi

echo ""

# ============================================================
# Install kubectl
# ============================================================

echo "📦 Installing kubectl..."

if command -v kubectl &> /dev/null; then
    echo "✅ kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    case "$OS" in
        Linux*)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        Darwin*)
            brew install kubectl
            ;;
        *)
            echo "❌ Unsupported OS for auto-install. Please install manually:"
            echo "   https://kubernetes.io/docs/tasks/tools/"
            ;;
    esac
    echo "✅ kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

echo ""

# ============================================================
# Install doctl (Digital Ocean CLI)
# ============================================================

echo "📦 Installing doctl..."

if command -v doctl &> /dev/null; then
    echo "✅ doctl already installed: $(doctl version)"
else
    case "$OS" in
        Linux*)
            cd ~
            wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
            tar xf ~/doctl-1.104.0-linux-amd64.tar.gz
            sudo mv ~/doctl /usr/local/bin
            rm ~/doctl-1.104.0-linux-amd64.tar.gz
            ;;
        Darwin*)
            brew install doctl
            ;;
        *)
            echo "❌ Unsupported OS for auto-install. Please install manually:"
            echo "   https://docs.digitalocean.com/reference/doctl/how-to/install/"
            ;;
    esac
    echo "✅ doctl installed: $(doctl version)"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     All Tools Installed Successfully!                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Authenticate with Digital Ocean:"
echo "   doctl auth init"
echo ""
echo "2. Configure Terraform variables:"
echo "   cd $(dirname $0)"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   vi terraform.tfvars"
echo ""
echo "3. Deploy infrastructure:"
echo "   make init"
echo "   make plan"
echo "   make apply"
echo ""
