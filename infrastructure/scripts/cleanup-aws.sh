#!/bin/bash
################################################################################
# AWS Infrastructure Cleanup Script
# Use this to forcefully delete all resources before terraform destroy
################################################################################

set -e

REGION="us-east-2"
CLUSTER_NAME="ecommerce-microservices-cluster"

echo "=========================================="
echo "AWS Infrastructure Cleanup"
echo "Region: $REGION"
echo "=========================================="
echo ""

# Function to delete all images from ECR repository
delete_ecr_images() {
    local repo_name=$1
    echo "Cleaning ECR repository: $repo_name"

    # Get all image digests
    local images=$(aws ecr list-images \
        --repository-name "$repo_name" \
        --region "$REGION" \
        --query 'imageIds[*]' \
        --output json 2>/dev/null || echo "[]")

    if [ "$images" != "[]" ]; then
        echo "  Deleting images from $repo_name..."
        aws ecr batch-delete-image \
            --repository-name "$repo_name" \
            --region "$REGION" \
            --image-ids "$images" || true
        echo "  ✓ Images deleted from $repo_name"
    else
        echo "  Repository $repo_name is empty or doesn't exist"
    fi
}

# Step 1: Delete all ECR images
echo "[1/4] Cleaning ECR repositories..."
SERVICES=(
    "ecommerce/service-discovery"
    "ecommerce/cloud-config"
    "ecommerce/user-service"
    "ecommerce/product-service"
    "ecommerce/order-service"
    "ecommerce/payment-service"
    "ecommerce/shipping-service"
    "ecommerce/favourite-service"
    "ecommerce/api-gateway"
)

for service in "${SERVICES[@]}"; do
    delete_ecr_images "$service"
done

echo ""

# Step 2: Delete EKS node groups
echo "[2/4] Deleting EKS node groups..."
NODE_GROUPS=$(aws eks list-nodegroups \
    --cluster-name "$CLUSTER_NAME" \
    --region "$REGION" \
    --query 'nodegroups[*]' \
    --output text 2>/dev/null || echo "")

if [ -n "$NODE_GROUPS" ]; then
    for ng in $NODE_GROUPS; do
        echo "  Deleting node group: $ng"
        aws eks delete-nodegroup \
            --cluster-name "$CLUSTER_NAME" \
            --nodegroup-name "$ng" \
            --region "$REGION" || true
    done

    echo "  Waiting for node groups to be deleted (this may take 5-10 minutes)..."
    for ng in $NODE_GROUPS; do
        aws eks wait nodegroup-deleted \
            --cluster-name "$CLUSTER_NAME" \
            --nodegroup-name "$ng" \
            --region "$REGION" 2>/dev/null || true
    done
    echo "  ✓ Node groups deleted"
else
    echo "  No node groups found"
fi

echo ""

# Step 3: Delete EKS cluster
echo "[3/4] Deleting EKS cluster..."
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
    echo "  Deleting cluster: $CLUSTER_NAME"
    aws eks delete-cluster \
        --name "$CLUSTER_NAME" \
        --region "$REGION" || true

    echo "  Waiting for cluster to be deleted (this may take 5-10 minutes)..."
    aws eks wait cluster-deleted \
        --name "$CLUSTER_NAME" \
        --region "$REGION" 2>/dev/null || true
    echo "  ✓ EKS cluster deleted"
else
    echo "  Cluster $CLUSTER_NAME not found"
fi

echo ""

# Step 4: Clean up orphaned ENIs (Elastic Network Interfaces)
echo "[4/4] Cleaning up orphaned network interfaces..."
ENIS=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=description,Values=*Amazon EKS*" \
    --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ENIS" ]; then
    for eni in $ENIS; do
        echo "  Deleting ENI: $eni"
        aws ec2 delete-network-interface \
            --network-interface-id "$eni" \
            --region "$REGION" 2>/dev/null || true
    done
    echo "  ✓ Orphaned ENIs deleted"
else
    echo "  No orphaned ENIs found"
fi

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "Now you can run: terraform destroy"
echo ""
