#!/bin/bash

# Script para ejecutar las pruebas E2E de los microservicios
# Los tests apuntan al API Gateway desplegado en AWS EKS (namespace dev)

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  E2E Tests - Ecommerce Microservices${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Obtener el LoadBalancer URL del API Gateway en el namespace dev
API_GATEWAY_URL=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -z "$API_GATEWAY_URL" ]; then
    echo -e "${YELLOW}⚠️  No se pudo obtener automáticamente la URL del API Gateway${NC}"
    echo -e "${YELLOW}   Usando URL por defecto...${NC}"
    API_GATEWAY_URL="ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com"
fi

export API_URL="http://${API_GATEWAY_URL}"

echo -e "${GREEN}✓ API Gateway URL:${NC} $API_URL"
echo ""

# Verificar que el API Gateway esté respondiendo
echo -e "${YELLOW}➜ Verificando conectividad con API Gateway...${NC}"
if curl -s --connect-timeout 5 "$API_URL/actuator/health" > /dev/null; then
    echo -e "${GREEN}✓ API Gateway está accesible${NC}"
else
    echo -e "${RED}✗ Error: No se puede conectar al API Gateway${NC}"
    echo -e "${RED}  Verifica que los servicios estén corriendo en K8s${NC}"
    exit 1
fi
echo ""

# Verificar que los servicios estén registrados en Eureka
echo -e "${YELLOW}➜ Verificando servicios registrados en Eureka...${NC}"
HEALTH_CHECK=$(curl -s "$API_URL/actuator/health" | grep -o '"status":"UP"' | wc -l)
if [ "$HEALTH_CHECK" -gt 0 ]; then
    echo -e "${GREEN}✓ Servicios están registrados en Eureka${NC}"
else
    echo -e "${YELLOW}⚠️  Advertencia: No se pudo verificar el estado de Eureka${NC}"
fi
echo ""

# Cambiar al directorio de tests
cd "$(dirname "$0")/tests"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Ejecutando Tests E2E con Maven${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Ejecutar los tests con Maven (usando verify para Failsafe plugin)
mvn clean verify -DAPI_URL="$API_URL"

TEST_RESULT=$?

echo ""
echo -e "${GREEN}========================================${NC}"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}  ✓ TESTS COMPLETADOS EXITOSAMENTE${NC}"
else
    echo -e "${RED}  ✗ ALGUNOS TESTS FALLARON${NC}"
fi
echo -e "${GREEN}========================================${NC}"
echo ""

exit $TEST_RESULT
