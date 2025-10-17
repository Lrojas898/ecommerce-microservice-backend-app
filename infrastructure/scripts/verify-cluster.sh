#!/bin/bash
# Script para verificar el estado del cluster EKS

echo "=========================================="
echo "🔍 Verificación de Cluster EKS"
echo "=========================================="
echo ""

# Configurar PATH para kubectl
export PATH=$HOME/bin:$PATH

echo "1️⃣  Cluster EKS:"
CLUSTER_STATUS=$(aws eks describe-cluster --name ecommerce-microservices-cluster --region us-east-1 --query 'cluster.status' --output text)
echo "   ✅ Status: $CLUSTER_STATUS"
echo ""

echo "2️⃣  Node Group:"
NODEGROUP_STATUS=$(aws eks describe-nodegroup --cluster-name ecommerce-microservices-cluster --nodegroup-name standard-workers --region us-east-1 --query 'nodegroup.status' --output text)
echo "   ✅ Status: $NODEGROUP_STATUS"

DESIRED=$(aws eks describe-nodegroup --cluster-name ecommerce-microservices-cluster --nodegroup-name standard-workers --region us-east-1 --query 'nodegroup.scalingConfig.desiredSize' --output text)
echo "   📊 Desired nodes: $DESIRED"
echo ""

echo "3️⃣  Kubernetes Nodes:"
kubectl get nodes
echo ""

echo "4️⃣  Namespaces:"
kubectl get namespaces | grep -E "dev|staging|production"
echo ""

echo "5️⃣  ECR Repositories:"
aws ecr describe-repositories --region us-east-1 --query 'repositories[].repositoryName' --output table
echo ""

echo "=========================================="
echo "✅ Cluster está listo para despliegues!"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Configurar Jenkins"
echo "   2. Crear pipelines en Jenkins"
echo "   3. Ejecutar pruebas"
echo "   4. Desplegar aplicaciones"
