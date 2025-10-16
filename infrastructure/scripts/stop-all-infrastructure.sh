#!/bin/bash
# Script para DETENER toda la infraestructura sin eliminarla
# Esto ahorra créditos de AWS cuando no estás trabajando

set -e

echo "=========================================="
echo "🛑 Deteniendo infraestructura AWS"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Detener instancia Jenkins
echo -e "${YELLOW}🔧 Deteniendo instancia Jenkins...${NC}"
JENKINS_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ecommerce-microservices-jenkins-server" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null)

if [ "$JENKINS_INSTANCE" != "None" ] && [ ! -z "$JENKINS_INSTANCE" ]; then
  aws ec2 stop-instances --instance-ids $JENKINS_INSTANCE
  echo -e "${GREEN}✅ Jenkins detenido: $JENKINS_INSTANCE${NC}"
else
  echo -e "${GREEN}✅ Jenkins ya está detenido${NC}"
fi

# 2. Escalar EKS node group a 0 (si existe)
echo ""
echo -e "${YELLOW}🔧 Escalando EKS node group a 0...${NC}"
CLUSTER_NAME="ecommerce-eks-cluster"
NODEGROUP_NAME="ecommerce-node-group"

# Verificar si el cluster existe
CLUSTER_EXISTS=$(aws eks describe-cluster --name $CLUSTER_NAME 2>/dev/null || echo "not-found")

if [ "$CLUSTER_EXISTS" != "not-found" ]; then
  # Verificar si el node group existe
  NODEGROUP_EXISTS=$(aws eks describe-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NODEGROUP_NAME 2>/dev/null || echo "not-found")

  if [ "$NODEGROUP_EXISTS" != "not-found" ]; then
    aws eks update-nodegroup-config \
      --cluster-name $CLUSTER_NAME \
      --nodegroup-name $NODEGROUP_NAME \
      --scaling-config minSize=0,maxSize=2,desiredSize=0
    echo -e "${GREEN}✅ EKS node group escalado a 0 nodos${NC}"
  else
    echo -e "${GREEN}✅ EKS node group no existe o ya está en 0${NC}"
  fi
else
  echo -e "${GREEN}✅ EKS cluster no existe${NC}"
fi

# 3. Resumen
echo ""
echo "=========================================="
echo -e "${GREEN}✅ Infraestructura detenida correctamente${NC}"
echo "=========================================="
echo ""
echo "📊 Estado:"
echo "  - Jenkins: DETENIDO (no se cobra)"
echo "  - EKS nodes: 0 (solo se cobra control plane ~\$0.10/hora)"
echo ""
echo "💰 Ahorro estimado: ~\$0.12/hora (~\$2.88/día)"
echo ""
echo "▶️  Para reiniciar: ./start-all-infrastructure.sh"
echo ""
