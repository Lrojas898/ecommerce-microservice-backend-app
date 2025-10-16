#!/bin/bash
# Script para INICIAR toda la infraestructura
# Usa esto cuando vuelvas a trabajar en el proyecto

set -e

echo "=========================================="
echo "▶️  Iniciando infraestructura AWS"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Iniciar instancia Jenkins
echo -e "${YELLOW}🔧 Iniciando instancia Jenkins...${NC}"
JENKINS_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ecommerce-microservices-jenkins-server" \
            "Name=instance-state-name,Values=stopped" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null)

if [ "$JENKINS_INSTANCE" != "None" ] && [ ! -z "$JENKINS_INSTANCE" ]; then
  aws ec2 start-instances --instance-ids $JENKINS_INSTANCE
  echo -e "${GREEN}✅ Jenkins iniciando: $JENKINS_INSTANCE${NC}"

  # Esperar a que arranque
  echo -e "${YELLOW}⏳ Esperando a que Jenkins esté listo...${NC}"
  aws ec2 wait instance-running --instance-ids $JENKINS_INSTANCE

  # Obtener IP pública
  JENKINS_IP=$(aws ec2 describe-instances \
    --instance-ids $JENKINS_INSTANCE \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  echo -e "${GREEN}✅ Jenkins corriendo en: http://$JENKINS_IP:8080${NC}"
else
  # Buscar si ya está corriendo
  JENKINS_INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=ecommerce-microservices-jenkins-server" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

  if [ "$JENKINS_INSTANCE" != "None" ] && [ ! -z "$JENKINS_INSTANCE" ]; then
    JENKINS_IP=$(aws ec2 describe-instances \
      --instance-ids $JENKINS_INSTANCE \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    echo -e "${GREEN}✅ Jenkins ya está corriendo en: http://$JENKINS_IP:8080${NC}"
  else
    echo -e "${YELLOW}⚠️  No se encontró instancia Jenkins${NC}"
  fi
fi

# 2. Escalar EKS node group de vuelta (si existe)
echo ""
echo -e "${YELLOW}🔧 Escalando EKS node group a 2 nodos...${NC}"
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
      --scaling-config minSize=2,maxSize=4,desiredSize=2
    echo -e "${GREEN}✅ EKS node group escalando a 2 nodos (tarda ~3 min)${NC}"

    # Configurar kubectl
    echo -e "${YELLOW}⏳ Configurando kubectl...${NC}"
    aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME
    echo -e "${GREEN}✅ kubectl configurado${NC}"
  else
    echo -e "${YELLOW}⚠️  EKS node group no existe${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  EKS cluster no existe (puedes trabajar sin él)${NC}"
fi

# 3. Resumen
echo ""
echo "=========================================="
echo -e "${GREEN}✅ Infraestructura iniciada${NC}"
echo "=========================================="
echo ""
echo "🌐 Accesos:"
if [ ! -z "$JENKINS_IP" ] && [ "$JENKINS_IP" != "None" ]; then
  echo "  - Jenkins: http://$JENKINS_IP:8080"
  echo "  - Contraseña inicial: ssh a la instancia y ejecuta:"
  echo "    cat /home/ec2-user/jenkins-password.txt"
fi
echo ""
echo "📝 Próximos pasos:"
echo "  1. Acceder a Jenkins y configurar"
echo "  2. Crear jobs/pipelines"
echo "  3. Cuando termines de trabajar: ./stop-all-infrastructure.sh"
echo ""
