#!/bin/bash
set -e

echo "=========================================="
echo "INSTALLING TERRAFORM IN JENKINS CONTAINER"
echo "=========================================="

# Find Jenkins container
JENKINS_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i jenkins | head -1)

if [ -z "$JENKINS_CONTAINER" ]; then
    echo "ERROR: Jenkins container not found"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    exit 1
fi

echo "Found Jenkins container: $JENKINS_CONTAINER"
echo ""

# Install Terraform inside Jenkins container
echo "[1/3] Installing Terraform dependencies..."
docker exec -u root $JENKINS_CONTAINER bash -c "
apt-get update -qq && \
apt-get install -y -qq wget unzip gnupg software-properties-common
"

echo ""
echo "[2/3] Downloading and installing Terraform..."
docker exec -u root $JENKINS_CONTAINER bash -c "
cd /tmp && \
wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip && \
unzip -q terraform_1.6.6_linux_amd64.zip && \
mv terraform /usr/local/bin/ && \
chmod +x /usr/local/bin/terraform && \
rm -f terraform_1.6.6_linux_amd64.zip
"

echo ""
echo "[3/3] Verifying Terraform installation..."
docker exec $JENKINS_CONTAINER terraform --version

echo ""
echo "=========================================="
echo "TERRAFORM INSTALLATION COMPLETED"
echo "=========================================="
echo ""
echo "Terraform version:"
docker exec $JENKINS_CONTAINER terraform --version
echo ""
echo "Now you can run the terraform pipeline in Jenkins!"
echo ""
