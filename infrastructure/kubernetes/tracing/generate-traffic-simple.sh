#!/bin/bash

# Script simplificado para generar tráfico sin reiniciar pods
# Usa este cuando ya tengas las imágenes correctas desplegadas

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "  Traffic Generator for Distributed Tracing"
echo "================================================"
echo ""

NAMESPACE=${1:-prod}
echo -e "${BLUE}Using namespace: ${NAMESPACE}${NC}"
echo ""

# Setup port-forward
echo -e "${YELLOW}Setting up port-forward to API Gateway...${NC}"

# Matar port-forwards anteriores
pkill -f "port-forward.*api-gateway" 2>/dev/null || true

# Crear nuevo port-forward
kubectl port-forward -n ${NAMESPACE} svc/api-gateway 18080:80 > /dev/null 2>&1 &
PF_PID=$!
echo "Port-forward started (PID: $PF_PID)"

sleep 3

API_URL="http://localhost:18080"

echo ""
echo -e "${GREEN}API Gateway available at: ${API_URL}${NC}"
echo ""

# Generar tráfico
echo -e "${YELLOW}Generating traffic to create traces...${NC}"
echo ""

# Hacer 20 requests variados
for i in {1..5}; do
  echo "Batch $i/5:"

  curl -s ${API_URL}/app/api/products > /dev/null 2>&1 && echo "  ✓ GET /products" || echo "  ✗ GET /products"
  curl -s ${API_URL}/app/api/users > /dev/null 2>&1 && echo "  ✓ GET /users" || echo "  ✗ GET /users"
  curl -s ${API_URL}/app/api/orders > /dev/null 2>&1 && echo "  ✓ GET /orders" || echo "  ✗ GET /orders"
  curl -s ${API_URL}/app/api/payments > /dev/null 2>&1 && echo "  ✓ GET /payments" || echo "  ✗ GET /payments"

  sleep 2
done

echo ""
echo -e "${GREEN}Traffic generation completed!${NC}"
echo ""

# Esperar a que traces se procesen
echo "Waiting 10 seconds for traces to be processed..."
sleep 10

# Verificar servicios en Jaeger
echo ""
echo -e "${YELLOW}Checking services registered in Jaeger...${NC}"
kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -- \
  curl -s http://jaeger-query.tracing.svc.cluster.local:16686/api/services

echo ""
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Done!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

echo "Next steps:"
echo ""
echo "1. Open Jaeger UI: http://localhost:16686"
echo ""
echo "2. In the 'Service' dropdown, select a service (e.g., 'api-gateway')"
echo ""
echo "3. Click 'Find Traces'"
echo ""
echo "4. You should see traces from the requests we just made!"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View logs:          kubectl logs -n ${NAMESPACE} deployment/api-gateway -f"
echo "  Kill port-forward:  kill ${PF_PID}"
echo "  Re-run script:      $0 ${NAMESPACE}"
echo ""

# Preguntar si quiere mantener el port-forward
echo -n "Keep port-forward running? (y/n): "
read -t 10 keep_running || keep_running="y"

if [ "$keep_running" != "y" ]; then
    echo "Stopping port-forward..."
    kill $PF_PID 2>/dev/null
    echo "Done!"
else
    echo ""
    echo -e "${GREEN}Port-forward still running on PID ${PF_PID}${NC}"
    echo "To stop it later: kill ${PF_PID}"
fi

echo ""
