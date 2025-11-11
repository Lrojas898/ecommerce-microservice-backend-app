#!/bin/bash

# Verification script for Jaeger Distributed Tracing
# This script checks if Jaeger is properly configured and running

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "  Jaeger Distributed Tracing Verification"
echo "================================================"
echo ""

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

FAILURES=0

# Test 1: Check namespace exists
echo -n "1. Checking tracing namespace exists... "
kubectl get namespace tracing &>/dev/null
if check_status; then
    :
else
    ((FAILURES++))
fi

# Test 2: Check Jaeger deployment
echo -n "2. Checking Jaeger deployment... "
kubectl get deployment jaeger -n tracing &>/dev/null
if check_status; then
    :
else
    ((FAILURES++))
fi

# Test 3: Check Jaeger pod is running
echo -n "3. Checking Jaeger pod is running... "
JAEGER_POD=$(kubectl get pods -n tracing -l app=jaeger -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$JAEGER_POD" ]; then
    POD_STATUS=$(kubectl get pod $JAEGER_POD -n tracing -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        check_status
    else
        echo -e "${RED}✗ FAIL${NC} (Status: $POD_STATUS)"
        ((FAILURES++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (No pod found)"
    ((FAILURES++))
fi

# Test 4: Check Jaeger services
echo -n "4. Checking Jaeger services... "
SERVICES=$(kubectl get svc -n tracing --no-headers | wc -l)
if [ "$SERVICES" -ge 3 ]; then
    check_status
else
    echo -e "${RED}✗ FAIL${NC} (Expected 3 services, found $SERVICES)"
    ((FAILURES++))
fi

# Test 5: Check collector endpoint
echo -n "5. Checking collector endpoint (9411)... "
kubectl get svc jaeger-collector -n tracing -o jsonpath='{.spec.ports[?(@.name=="zipkin")].port}' | grep -q 9411
if check_status; then
    :
else
    ((FAILURES++))
fi

# Test 6: Check query UI endpoint
echo -n "6. Checking query UI endpoint (16686)... "
kubectl get svc jaeger-query -n tracing -o jsonpath='{.spec.ports[0].port}' | grep -q 16686
if check_status; then
    :
else
    ((FAILURES++))
fi

# Test 7: Check Jaeger health
if [ -n "$JAEGER_POD" ] && [ "$POD_STATUS" == "Running" ]; then
    echo -n "7. Checking Jaeger health endpoint... "
    kubectl exec -n tracing $JAEGER_POD -- wget -q -O- http://localhost:14269/ &>/dev/null
    if check_status; then
        :
    else
        ((FAILURES++))
    fi
fi

# Test 8: Check ConfigMap
echo -n "8. Checking sampling configuration... "
kubectl get configmap jaeger-sampling-config -n tracing &>/dev/null
if check_status; then
    :
else
    ((FAILURES++))
fi

# Test 9: Check microservices configuration
echo -n "9. Checking microservices Jaeger config... "
CONFIGURED=0
for service in user-service product-service order-service payment-service shipping-service favourite-service api-gateway; do
    if grep -q "SPRING_ZIPKIN_BASE_URL" "../base/${service}.yaml" 2>/dev/null; then
        ((CONFIGURED++))
    fi
done
if [ "$CONFIGURED" -ge 5 ]; then
    check_status
else
    echo -e "${YELLOW}⚠ PARTIAL${NC} ($CONFIGURED/7 services configured)"
fi

echo ""
echo "================================================"

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All checks passed! ✓${NC}"
    echo ""
    echo "Jaeger UI Access:"
    echo "  Port-forward: kubectl port-forward -n tracing svc/jaeger-query 16686:16686"
    echo "  URL: http://localhost:16686"
    echo ""

    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "")
    if [ -n "$MINIKUBE_IP" ]; then
        echo "  Minikube: http://$MINIKUBE_IP:30686"
        echo ""
    fi

    echo "Next Steps:"
    echo "  1. Generate traffic (run E2E tests or use the application)"
    echo "  2. Open Jaeger UI and search for traces"
    echo "  3. Select a service and click 'Find Traces'"
    echo ""
    echo "Useful Commands:"
    echo "  View pods:    kubectl get pods -n tracing"
    echo "  View logs:    kubectl logs -n tracing deployment/jaeger"
    echo "  View services: kubectl get svc -n tracing"
    echo ""
else
    echo -e "${RED}$FAILURES check(s) failed ✗${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check Jaeger logs: kubectl logs -n tracing deployment/jaeger"
    echo "  2. Check pod status: kubectl describe pod -n tracing $JAEGER_POD"
    echo "  3. Check events: kubectl get events -n tracing --sort-by='.lastTimestamp'"
    echo "  4. Redeploy: kubectl delete namespace tracing && ./deploy-jaeger.sh"
    echo ""
    exit 1
fi

echo "================================================"
echo ""

# Show resource usage
echo -e "${BLUE}Resource Usage:${NC}"
kubectl top pod -n tracing 2>/dev/null || echo "  (metrics-server not available)"

echo ""
echo "Documentation: docs/DISTRIBUTED_TRACING.md"
