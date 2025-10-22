#!/bin/bash
################################################################################
# Jenkins Post-Installation Setup Script
# This script installs all required tools inside the Jenkins container/instance
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "Starting Jenkins Configuration Setup"
echo "=========================================="

# Update package lists
echo "[1/8] Updating package lists..."
apt-get update -y

# Install basic tools
echo "[2/8] Installing basic tools..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    vim \
    jq \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker (if not already installed)
echo "[3/8] Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add jenkins user to docker group
    usermod -aG docker jenkins
else
    echo "Docker already installed, skipping..."
fi

# Install AWS CLI v2
echo "[4/8] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "AWS CLI already installed, skipping..."
fi

# Install kubectl
echo "[5/8] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "kubectl already installed, skipping..."
fi

# Install Maven
echo "[6/8] Installing Maven..."
if ! command -v mvn &> /dev/null; then
    apt-get install -y maven
else
    echo "Maven already installed, skipping..."
fi

# Install Java 17 (if not already installed)
echo "[7/8] Installing Java 17..."
if ! java -version 2>&1 | grep -q "17"; then
    apt-get install -y openjdk-17-jdk
    # Set Java 17 as default
    update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
else
    echo "Java 17 already installed, skipping..."
fi

# Configure AWS CLI for Jenkins user
echo "[8/8] Configuring AWS credentials..."
mkdir -p /var/lib/jenkins/.aws

cat > /var/lib/jenkins/.aws/config <<EOF
[default]
region = us-east-2
output = json
EOF

# Set proper permissions
chown -R jenkins:jenkins /var/lib/jenkins/.aws

# Configure kubectl for EKS
echo "Configuring kubectl for EKS cluster..."
su - jenkins -c "aws eks update-kubeconfig --name ecommerce-microservices-cluster --region us-east-2" || echo "EKS cluster not ready yet, skip this step"

# Restart Jenkins to apply all changes
echo "=========================================="
echo "Configuration complete!"
echo "=========================================="
echo ""
echo "Installed tools:"
echo "  - Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "  - AWS CLI: $(aws --version 2>/dev/null || echo 'Not installed')"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Not installed')"
echo "  - Maven: $(mvn -version 2>/dev/null | head -n1 || echo 'Not installed')"
echo "  - Java: $(java -version 2>&1 | head -n1 || echo 'Not installed')"
echo ""
echo "=========================================="
echo "IMPORTANT NEXT STEPS:"
echo "=========================================="
echo "1. Configure AWS credentials:"
echo "   Run: aws configure"
echo "   Enter your AWS Access Key ID and Secret Access Key"
echo ""
echo "2. Restart Jenkins service:"
echo "   systemctl restart jenkins"
echo ""
echo "3. Install Jenkins plugins (via UI):"
echo "   - Pipeline"
echo "   - Git"
echo "   - Docker Pipeline"
echo "   - Kubernetes"
echo "   - AWS Steps"
echo "   - GitHub Integration"
echo ""
echo "4. Create Jenkins credentials:"
echo "   - AWS credentials (Access Key)"
echo "   - GitHub credentials (PAT)"
echo "   - Docker Registry credentials"
echo ""
echo "=========================================="
