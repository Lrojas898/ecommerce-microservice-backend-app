#!/bin/bash
# Script to import existing EBS CSI Driver resources into Terraform state

set -e

ACCOUNT_ID="020951019497"
REGION="us-east-2"
CLUSTER_NAME="ecommerce-microservices-cluster"
OIDC_ID="862E07CA11B9C356289BAD82F20ECB4E"

echo "======================================"
echo "Importing EBS CSI Driver Resources"
echo "======================================"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Terraform not initialized. Running terraform init..."
    terraform init
fi

# Import OIDC Provider
echo ""
echo "1. Importing OIDC Provider..."
terraform import aws_iam_openid_connect_provider.eks \
  "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}" \
  || echo "Already imported or error occurred"

# Import IAM Role
echo ""
echo "2. Importing IAM Role..."
terraform import aws_iam_role.ebs_csi_driver AmazonEKS_EBS_CSI_DriverRole \
  || echo "Already imported or error occurred"

# Import IAM Role Policy Attachment
echo ""
echo "3. Importing IAM Role Policy Attachment..."
terraform import aws_iam_role_policy_attachment.ebs_csi_driver \
  "AmazonEKS_EBS_CSI_DriverRole/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" \
  || echo "Already imported or error occurred"

# Import EBS CSI Driver Addon
echo ""
echo "4. Importing EBS CSI Driver Addon..."
terraform import aws_eks_addon.ebs_csi_driver \
  "${CLUSTER_NAME}:aws-ebs-csi-driver" \
  || echo "Already imported or error occurred"

echo ""
echo "======================================"
echo "Import Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to verify the state"
echo "2. If there are changes, review them carefully"
echo "3. Run 'terraform apply' if needed to align resources"
echo ""
