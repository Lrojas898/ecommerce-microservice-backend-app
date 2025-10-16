#!/bin/bash
# Script para verificar el estado de Jenkins

set -e

JENKINS_IP="98.91.95.121"
INSTANCE_ID="i-0af2fd5aff9ff71e8"

echo "=========================================="
echo "🔍 Diagnóstico de Jenkins"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Estado de la instancia
echo -e "${YELLOW}1️⃣ Estado de la instancia EC2:${NC}"
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,LaunchTime]' \
  --output table
echo ""

# 2. Probar conectividad SSH (puerto 22)
echo -e "${YELLOW}2️⃣ Probando conectividad SSH (puerto 22):${NC}"
nc -zv -w 3 $JENKINS_IP 22 2>&1 || echo -e "${RED}❌ Puerto 22 no responde${NC}"
echo ""

# 3. Probar conectividad Jenkins (puerto 8080)
echo -e "${YELLOW}3️⃣ Probando conectividad Jenkins (puerto 8080):${NC}"
nc -zv -w 3 $JENKINS_IP 8080 2>&1 || echo -e "${RED}❌ Puerto 8080 no responde (Jenkins aún no está listo)${NC}"
echo ""

# 4. Intentar curl a Jenkins
echo -e "${YELLOW}4️⃣ Probando HTTP a Jenkins:${NC}"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --connect-timeout 5 http://$JENKINS_IP:8080 2>&1 || echo -e "${RED}❌ Jenkins no responde${NC}"
echo ""

# 5. Ver logs de consola de EC2
echo -e "${YELLOW}5️⃣ Últimas 30 líneas de logs de arranque:${NC}"
aws ec2 get-console-output --instance-id $INSTANCE_ID --output text 2>/dev/null | tail -30 || echo -e "${RED}❌ No hay logs disponibles aún${NC}"
echo ""

echo "=========================================="
echo -e "${YELLOW}📝 Recomendaciones:${NC}"
echo ""
echo "Si puerto 8080 no responde, opciones:"
echo "  1. Esperar 2-3 minutos más (instalación en progreso)"
echo "  2. Conectar por SSH para ver logs en vivo:"
echo "     ssh ec2-user@$JENKINS_IP"
echo "     sudo tail -f /var/log/cloud-init-output.log"
echo "     sudo systemctl status jenkins"
echo ""
echo "  3. Si necesitas key SSH, créala primero:"
echo "     aws ec2 create-key-pair --key-name jenkins-key --query 'KeyMaterial' --output text > jenkins-key.pem"
echo "     chmod 400 jenkins-key.pem"
echo "     ssh -i jenkins-key.pem ec2-user@$JENKINS_IP"
echo ""
