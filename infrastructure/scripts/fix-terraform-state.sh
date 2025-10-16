#!/bin/bash
# Script para arreglar el estado fallido de Terraform

set -e

echo "=========================================="
echo "🔧 Arreglando estado de Terraform"
echo "=========================================="
echo ""

cd infrastructure/terraform

# 1. Eliminar node group fallido del state
echo "1. Removiendo node group fallido del estado..."
terraform state rm module.eks.aws_eks_node_group.main || true

# 2. Importar Jenkins actual (no modificable)
echo "2. Manteniendo Jenkins actual (no modificable en Free Tier)..."

# 3. Aplicar solo creación de EKS con t2.micro
echo "3. Aplicando cambios con instancias Free Tier..."
terraform apply -auto-approve

echo ""
echo "=========================================="
echo "✅ Estado corregido"
echo "=========================================="
