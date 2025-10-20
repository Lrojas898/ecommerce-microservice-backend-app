#!/bin/bash
set -e

JENKINS_CONTAINER=$(docker ps --filter "ancestor=jenkins/jenkins" --format "{{.Names}}" | head -1)

if [ -z "$JENKINS_CONTAINER" ]; then
    JENKINS_CONTAINER=$(docker ps --filter "name=jenkins" --format "{{.Names}}" | head -1)
fi

if [ -z "$JENKINS_CONTAINER" ]; then
    echo "Error: No Jenkins container found"
    exit 1
fi

echo "Configuring kubectl in Jenkins container: $JENKINS_CONTAINER"

docker exec -u root $JENKINS_CONTAINER bash -c '
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi

if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

mkdir -p /var/jenkins_home/.kube
aws eks update-kubeconfig --name ecommerce-microservices-cluster --region us-east-1 --kubeconfig /var/jenkins_home/.kube/config

chown -R jenkins:jenkins /var/jenkins_home/.kube

echo "===== Verification ====="
kubectl version --client
kubectl get nodes
echo "===== Configuration Complete ====="
'

echo "kubectl configured successfully in Jenkins"
