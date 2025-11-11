#!/bin/bash

# Script para generar tráfico de prueba y verificar tracing
# Esto generará traces que podrás ver en Jaeger UI

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

# Verificar namespace
NAMESPACE=${1:-dev}
echo -e "${BLUE}Using namespace: ${NAMESPACE}${NC}"
echo ""

# Paso 1: Redesplegar microservicios con nueva configuración
echo -e "${YELLOW}Step 1: Redeploying microservices with Jaeger config...${NC}"
echo "This ensures they have the ZIPKIN_BASE_URL environment variable"
echo ""

SERVICES=(
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
    "api-gateway"
)

for service in "${SERVICES[@]}"; do
    echo -n "  Restarting ${service}... "
    kubectl rollout restart deployment/${service} -n ${NAMESPACE} 2>/dev/null && echo "✓" || echo "⚠ (not found)"
done

echo ""
echo -e "${YELLOW}Waiting 30 seconds for pods to restart...${NC}"
sleep 30

# Paso 2: Verificar que los pods están ready
echo ""
echo -e "${YELLOW}Step 2: Verifying pods are ready...${NC}"
kubectl wait --for=condition=ready pod -l app=api-gateway -n ${NAMESPACE} --timeout=120s 2>/dev/null || echo "⚠ API Gateway not ready yet"

# Paso 3: Setup port-forward
echo ""
echo -e "${YELLOW}Step 3: Setting up port-forward to API Gateway...${NC}"

# Matar port-forwards anteriores
pkill -f "port-forward.*api-gateway" 2>/dev/null || true

# Crear nuevo port-forward
kubectl port-forward -n ${NAMESPACE} svc/api-gateway 18080:80 > /dev/null 2>&1 &
PF_PID=$!
echo "Port-forward started (PID: $PF_PID)"

sleep 3

# Verificar que el port-forward está activo
if ! ps -p $PF_PID > /dev/null; then
    echo -e "${RED}Error: Port-forward failed to start${NC}"
    exit 1
fi

API_URL="http://localhost:18080"

echo ""
echo -e "${GREEN}API Gateway available at: ${API_URL}${NC}"
echo ""

# Paso 4: Generar tráfico
echo -e "${YELLOW}Step 4: Generating traffic (this will create traces)...${NC}"
echo ""

# Función para hacer requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local desc=$4

    echo -n "  ${desc}... "

    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}${endpoint}" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}${endpoint}" \
            -H "Content-Type: application/json" \
            -d "${data}" 2>/dev/null)
    fi

    status_code=$(echo "$response" | tail -n1)

    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        echo -e "${GREEN}✓ (${status_code})${NC}"
        return 0
    elif [ "$status_code" -ge 400 ]; then
        echo -e "${YELLOW}⚠ (${status_code})${NC}"
        return 1
    else
        echo -e "${RED}✗ (Connection failed)${NC}"
        return 1
    fi
}

echo "Making test requests to generate traces..."
echo ""

# Request 1: Get products
make_request "GET" "/app/api/products" "" "GET /app/api/products"
sleep 1

# Request 2: Get specific product
make_request "GET" "/app/api/products/1" "" "GET /app/api/products/1"
sleep 1

# Request 3: Get users
make_request "GET" "/app/api/users" "" "GET /app/api/users"
sleep 1

# Request 4: Get orders
make_request "GET" "/app/api/orders" "" "GET /app/api/orders"
sleep 1

# Request 5: Get payments
make_request "GET" "/app/api/payments" "" "GET /app/api/payments"
sleep 1

# Request 6: Create a user
USER_DATA='{
  "firstName": "Test",
  "lastName": "User",
  "imageUrl": "https://via.placeholder.com/150",
  "email": "test'$(date +%s)'@example.com",
  "phone": "1234567890",
  "credential": {
    "username": "testuser'$(date +%s)'",
    "password": "password123",
    "roleBasedAuthority": "ROLE_USER"
  }
}'
make_request "POST" "/app/api/users" "$USER_DATA" "POST /app/api/users (create user)"
sleep 1

# Request 7: Get carts
make_request "GET" "/app/api/carts" "" "GET /app/api/carts"
sleep 1

# Request 8: Get shipping
make_request "GET" "/app/api/shippings" "" "GET /app/api/shippings"
sleep 1

# Request 9: Get favourites
make_request "GET" "/app/api/favourites" "" "GET /app/api/favourites"
sleep 1

# Request 10: Browse products again
make_request "GET" "/app/api/products?page=0&size=10" "" "GET /app/api/products (paginated)"
sleep 1

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Traffic generation completed!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Paso 5: Verificar traces
echo -e "${YELLOW}Step 5: Verifying traces were sent to Jaeger...${NC}"
echo ""

# Esperar un poco para que los traces se procesen
echo "Waiting 5 seconds for traces to be processed..."
sleep 5

# Verificar logs de microservicios para ver Trace IDs
echo ""
echo "Checking for Trace IDs in logs..."
echo ""

for service in "${SERVICES[@]}"; do
    echo -n "  ${service}: "
    TRACE_LOG=$(kubectl logs -n ${NAMESPACE} deployment/${service} --tail=20 2>/dev/null | grep -o '\[.*,[a-f0-9]\{16\},' | head -1 || echo "")
    if [ -n "$TRACE_LOG" ]; then
        TRACE_ID=$(echo "$TRACE_LOG" | grep -o '[a-f0-9]\{16\}' | head -1)
        echo -e "${GREEN}✓ Trace ID found: ${TRACE_ID}${NC}"
    else
        echo -e "${YELLOW}⚠ No trace IDs in recent logs${NC}"
    fi
done

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Done!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

echo "Next steps:"
echo ""
echo "1. Open Jaeger UI: http://localhost:16686"
echo ""
echo "2. In the 'Service' dropdown, you should now see:"
echo "   - api-gateway"
echo "   - user-service"
echo "   - product-service"
echo "   - order-service"
echo "   - payment-service"
echo "   - etc..."
echo ""
echo "3. Select a service (e.g., 'api-gateway')"
echo ""
echo "4. Click 'Find Traces'"
echo ""
echo "5. You should see traces from the requests we just made!"
echo ""
echo "6. Click on any trace to see the full distributed trace"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View API Gateway logs:  kubectl logs -n ${NAMESPACE} deployment/api-gateway -f"
echo "  View User Service logs: kubectl logs -n ${NAMESPACE} deployment/user-service -f"
echo "  Kill port-forward:      kill ${PF_PID}"
echo "  Re-run this script:     $0"
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
