#!/bin/bash

###############################################################################
# SonarQube Access Information Script
#
# This script displays access information for the deployed SonarQube instance
#
# Usage: ./access-sonarqube.sh
###############################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="sonarqube"

echo ""
echo "========================================"
echo "  SonarQube Access Information"
echo "========================================"
echo ""

# Check if SonarQube is deployed
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}[WARN]${NC} SonarQube is not deployed yet."
    echo "Please run ./deploy-sonarqube.sh first"
    exit 1
fi

# Get pod status
echo -e "${BLUE}📊 Pod Status:${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""

# Get service info
echo -e "${BLUE}🌐 Service Information:${NC}"
kubectl get svc -n ${NAMESPACE}
echo ""

# Get NodePort
NODEPORT=$(kubectl get svc sonarqube-external -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

# Try to get external IP
EXTERNAL_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)

# If no external IP, try internal IP
if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
fi

# Check if SonarQube is ready
SONARQUBE_READY=$(kubectl get pods -n ${NAMESPACE} -l app=sonarqube -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

echo ""
echo "========================================"
echo -e "${GREEN}📍 Access URLs:${NC}"
echo "========================================"
echo ""

if [ "$SONARQUBE_READY" == "True" ]; then
    echo -e "${GREEN}✓${NC} SonarQube is ready!"
    echo ""
    echo "   External URL: http://${EXTERNAL_IP}:${NODEPORT}"
    echo ""
else
    echo -e "${YELLOW}⚠${NC} SonarQube is not ready yet"
    echo ""
    echo "   Expected URL: http://${EXTERNAL_IP}:${NODEPORT}"
    echo "   (Will be available once the pod is ready)"
    echo ""
fi

echo "========================================"
echo -e "${BLUE}🔐 Default Credentials:${NC}"
echo "========================================"
echo ""
echo "   Username: admin"
echo "   Password: admin"
echo "   (Change password on first login)"
echo ""

echo "========================================"
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo "========================================"
echo ""
echo "   View logs:"
echo "   kubectl logs -f deployment/sonarqube -n ${NAMESPACE}"
echo ""
echo "   View PostgreSQL logs:"
echo "   kubectl logs -f deployment/sonarqube-postgres -n ${NAMESPACE}"
echo ""
echo "   Restart SonarQube:"
echo "   kubectl rollout restart deployment/sonarqube -n ${NAMESPACE}"
echo ""
echo "   Port-forward (alternative access):"
echo "   kubectl port-forward -n ${NAMESPACE} svc/sonarqube 9000:9000"
echo "   Then access: http://localhost:9000"
echo ""
echo "   Delete SonarQube:"
echo "   kubectl delete namespace ${NAMESPACE}"
echo ""

# Show PVC status
echo "========================================"
echo -e "${BLUE}💾 Storage Status:${NC}"
echo "========================================"
echo ""
kubectl get pvc -n ${NAMESPACE}
echo ""

# Check if there are any issues
PODS_NOT_READY=$(kubectl get pods -n ${NAMESPACE} --field-selector=status.phase!=Running 2>/dev/null | grep -v "NAME" | wc -l)

if [ "$PODS_NOT_READY" -gt 0 ]; then
    echo "========================================"
    echo -e "${YELLOW}⚠ Troubleshooting:${NC}"
    echo "========================================"
    echo ""
    echo "Some pods are not running. Check logs:"
    echo ""
    kubectl get pods -n ${NAMESPACE} --field-selector=status.phase!=Running
    echo ""
fi

echo "========================================"
echo ""
