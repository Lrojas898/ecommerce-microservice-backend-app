#!/bin/bash

# =============================================================================
# Deploy Alerting Stack (Alertmanager + Alert Rules)
# E-Commerce Microservices - ICESI
# =============================================================================

set -e

echo "======================================================================"
echo "  Deploying Alerting Stack for E-Commerce Microservices"
echo "======================================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo -e "${YELLOW}Warning: 'monitoring' namespace doesn't exist${NC}"
    echo -e "${YELLOW}Please deploy Prometheus + Grafana first using ./deploy-monitoring.sh${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1/6: Deploying Alert Rules${NC}"
kubectl apply -f prometheus-alert-rules.yaml
echo ""

echo -e "${GREEN}Step 2/6: Deploying Alertmanager Configuration${NC}"
kubectl apply -f alertmanager-config.yaml
echo ""

echo -e "${GREEN}Step 3/6: Deploying Alertmanager${NC}"
kubectl apply -f alertmanager.yaml
echo ""

echo -e "${GREEN}Step 4/6: Updating Prometheus Configuration${NC}"
kubectl apply -f prometheus-config.yaml
echo ""

echo -e "${GREEN}Step 5/6: Updating Prometheus Deployment (to mount alert rules)${NC}"
kubectl apply -f prometheus.yaml
echo ""

echo -e "${GREEN}Step 6/6: Restarting Prometheus to reload configuration${NC}"
kubectl rollout restart deployment/prometheus -n monitoring
echo ""

echo -e "${YELLOW}Waiting for Alertmanager to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/alertmanager -n monitoring 2>/dev/null || true
echo ""

echo -e "${YELLOW}Waiting for Prometheus to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/prometheus -n monitoring 2>/dev/null || true
echo ""

echo "======================================================================"
echo -e "${GREEN}Alerting Stack Deployed Successfully!${NC}"
echo "======================================================================"
echo ""
echo "Deployed components:"
echo "  - Alertmanager: Handles alert notifications"
echo "  - Alert Rules: 15+ rules for critical situations"
echo "  - Prometheus: Updated with alerting configuration"
echo ""
echo "======================================================================"
echo "Access URLs:"
echo "======================================================================"
echo ""

# Try to get Minikube IP
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unavailable")
    echo "Alertmanager UI:"
    echo "  - External (NodePort): http://${MINIKUBE_IP}:30093"
    echo "  - Port-forward: kubectl port-forward -n monitoring svc/alertmanager 9093:9093"
    echo "                  Then open: http://localhost:9093"
    echo ""
    echo "Prometheus UI (to view alerts):"
    echo "  - External (NodePort): http://${MINIKUBE_IP}:30090"
    echo "  - Go to: Status -> Rules (to see alert rules)"
    echo "  - Go to: Alerts (to see active/firing alerts)"
else
    echo "Alertmanager UI:"
    echo "  - Port-forward: kubectl port-forward -n monitoring svc/alertmanager 9093:9093"
    echo "                  Then open: http://localhost:9093"
    echo ""
    echo "Prometheus UI:"
    echo "  - Port-forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    echo "                  Then open: http://localhost:9090"
    echo "  - Go to: Status -> Rules"
    echo "  - Go to: Alerts"
fi

echo ""
echo "======================================================================"
echo "Alert Rules Configured:"
echo "======================================================================"
echo ""
echo "CRITICAL Alerts:"
echo "  - ServiceDown: Service unreachable for >1 minute"
echo "  - APIGatewayDown: API Gateway unavailable (blocks all traffic)"
echo "  - EurekaDown: Service Discovery down"
echo "  - HighMemoryUsage: Heap memory >85% for >5 minutes"
echo "  - HighHTTPErrorRate: 5xx errors >5% for >2 minutes"
echo "  - PaymentServiceErrors: Payment service errors (revenue impact)"
echo ""
echo "WARNING Alerts:"
echo "  - HighCPUUsage: CPU >80% for >5 minutes"
echo "  - HighResponseTime: Average response time >1s"
echo "  - OrderCreationLatency: Order creation >2s"
echo "  - HighDatabaseConnectionPoolUsage: DB connections >80%"
echo "  - FrequentPodRestarts: Pod restarting frequently"
echo ""
echo "======================================================================"
echo "Verification Commands:"
echo "======================================================================"
echo ""
echo "# View all resources"
echo "kubectl get all -n monitoring"
echo ""
echo "# View alert rules"
echo "kubectl get configmap prometheus-alert-rules -n monitoring -o yaml"
echo ""
echo "# View Alertmanager logs"
echo "kubectl logs -f deployment/alertmanager -n monitoring"
echo ""
echo "# View Prometheus logs"
echo "kubectl logs -f deployment/prometheus -n monitoring"
echo ""
echo "# Check if alert rules are loaded in Prometheus"
echo "kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "# Then open: http://localhost:9090/rules"
echo ""
echo "======================================================================"
echo "Next Steps:"
echo "======================================================================"
echo ""
echo "1. Open Prometheus UI and go to 'Alerts' to see configured alerts"
echo "2. Alerts will show in 3 states:"
echo "   - Inactive (green): Everything is OK"
echo "   - Pending (yellow): Condition met but waiting for 'for' duration"
echo "   - Firing (red): Alert is active and sent to Alertmanager"
echo ""
echo "3. To configure Slack/Email notifications:"
echo "   - Edit: alertmanager-config.yaml"
echo "   - Uncomment and configure the receiver section"
echo "   - Re-apply: kubectl apply -f alertmanager-config.yaml"
echo "   - Restart: kubectl rollout restart deployment/alertmanager -n monitoring"
echo ""
echo "4. To test an alert:"
echo "   - Scale down a service: kubectl scale deployment/user-service --replicas=0 -n dev"
echo "   - Wait ~2 minutes"
echo "   - Check Prometheus UI -> Alerts (should see ServiceDown firing)"
echo "   - Check Alertmanager UI (should see alert listed)"
echo "   - Scale back up: kubectl scale deployment/user-service --replicas=1 -n dev"
echo ""
echo -e "${GREEN}Alerting setup complete!${NC}"
echo "======================================================================"
