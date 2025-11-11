#!/bin/bash

# =============================================================================
# Deploy ELK Stack (Elasticsearch + Kibana + Filebeat)
# E-Commerce Microservices - ICESI
# =============================================================================

set -e

echo "======================================================================"
echo "  Deploying ELK Stack for E-Commerce Microservices"
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

echo -e "${GREEN}Step 1/6: Creating logging namespace${NC}"
kubectl apply -f namespace.yaml
echo ""

echo -e "${GREEN}Step 2/6: Deploying Elasticsearch${NC}"
echo "  - Creating PersistentVolumeClaim (5Gi)"
echo "  - Deploying Elasticsearch (single-node mode)"
kubectl apply -f elasticsearch.yaml
echo ""

echo -e "${YELLOW}Waiting for Elasticsearch to be ready (this may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n logging 2>/dev/null || {
    echo -e "${YELLOW}Timeout waiting for Elasticsearch. Checking pod status...${NC}"
    kubectl get pods -n logging -l app=elasticsearch
}
echo ""

echo -e "${GREEN}Step 3/6: Deploying Kibana${NC}"
kubectl apply -f kibana.yaml
echo ""

echo -e "${YELLOW}Waiting for Kibana to be ready (this may take 1-2 minutes)...${NC}"
kubectl wait --for=condition=available --timeout=240s deployment/kibana -n logging 2>/dev/null || {
    echo -e "${YELLOW}Timeout waiting for Kibana. Checking pod status...${NC}"
    kubectl get pods -n logging -l app=kibana
}
echo ""

echo -e "${GREEN}Step 4/6: Deploying Filebeat Configuration${NC}"
kubectl apply -f filebeat-config.yaml
echo ""

echo -e "${GREEN}Step 5/6: Deploying Filebeat DaemonSet${NC}"
echo "  - Filebeat will run on every node"
echo "  - Collecting logs from all containers"
kubectl apply -f filebeat.yaml
echo ""

echo -e "${YELLOW}Waiting for Filebeat pods to be ready...${NC}"
sleep 10
echo ""

echo -e "${GREEN}Step 6/6: Verifying deployment${NC}"
kubectl get all -n logging
echo ""

echo "======================================================================"
echo -e "${GREEN}ELK Stack Deployed Successfully!${NC}"
echo "======================================================================"
echo ""
echo "Deployed components:"
echo "  - Elasticsearch: Log storage and search engine"
echo "  - Kibana: Log visualization UI"
echo "  - Filebeat: Log collector (running on every node)"
echo ""
echo "======================================================================"
echo "Access URLs:"
echo "======================================================================"
echo ""

# Try to get Minikube IP
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unavailable")
    echo "Kibana UI (Log Visualization):"
    echo "  - External (NodePort): http://${MINIKUBE_IP}:30561"
    echo "  - Port-forward: kubectl port-forward -n logging svc/kibana 5601:5601"
    echo "                  Then open: http://localhost:5601"
    echo ""
    echo "Elasticsearch API:"
    echo "  - External (NodePort): http://${MINIKUBE_IP}:30920"
    echo "  - Health check: curl http://${MINIKUBE_IP}:30920/_cluster/health"
else
    echo "Kibana UI:"
    echo "  - Port-forward: kubectl port-forward -n logging svc/kibana 5601:5601"
    echo "                  Then open: http://localhost:5601"
    echo ""
    echo "Elasticsearch:"
    echo "  - Port-forward: kubectl port-forward -n logging svc/elasticsearch 9200:9200"
    echo "  - Health check: curl http://localhost:9200/_cluster/health"
fi

echo ""
echo "======================================================================"
echo "First Steps in Kibana:"
echo "======================================================================"
echo ""
echo "1. Open Kibana UI (see URLs above)"
echo "2. Wait for Kibana to fully load (first time takes ~1 minute)"
echo "3. Click on 'Explore on my own' (skip tutorial)"
echo "4. Go to: Menu (☰) -> Management -> Stack Management -> Index Patterns"
echo "5. Click 'Create index pattern'"
echo "6. Enter pattern: ecommerce-logs-*"
echo "7. Select timestamp field: @timestamp"
echo "8. Click 'Create index pattern'"
echo "9. Go to: Menu (☰) -> Analytics -> Discover"
echo "10. You should see logs from your microservices!"
echo ""
echo "======================================================================"
echo "Useful Queries in Kibana Discover:"
echo "======================================================================"
echo ""
echo "Filter by service:"
echo "  kubernetes.labels.app: \"user-service\""
echo ""
echo "Filter by namespace:"
echo "  kubernetes.namespace: \"prod\""
echo ""
echo "Filter by log level (if JSON logs):"
echo "  level: \"ERROR\""
echo ""
echo "Search for text:"
echo "  Just type in the search box: \"Exception\""
echo ""
echo "======================================================================"
echo "Verification Commands:"
echo "======================================================================"
echo ""
echo "# View all logging resources"
echo "kubectl get all -n logging"
echo ""
echo "# Check Elasticsearch health"
echo "kubectl exec -n logging deployment/elasticsearch -- curl -s http://localhost:9200/_cluster/health | jq"
echo ""
echo "# View Filebeat logs"
echo "kubectl logs -n logging daemonset/filebeat --tail=50"
echo ""
echo "# Check if logs are being indexed"
echo "kubectl exec -n logging deployment/elasticsearch -- curl -s http://localhost:9200/_cat/indices?v"
echo ""
echo "# View Kibana logs"
echo "kubectl logs -n logging deployment/kibana --tail=50"
echo ""
echo "======================================================================"
echo "Troubleshooting:"
echo "======================================================================"
echo ""
echo "If Elasticsearch pod is pending or crashing:"
echo "  - Check: kubectl describe pod -n logging <elasticsearch-pod>"
echo "  - May need more memory/CPU resources"
echo "  - Try: kubectl delete pod -n logging <elasticsearch-pod> (recreates)"
echo ""
echo "If Kibana shows 'Kibana server is not ready yet':"
echo "  - Wait 1-2 minutes for Elasticsearch to fully start"
echo "  - Check: kubectl logs -n logging deployment/kibana"
echo ""
echo "If no logs appear in Kibana:"
echo "  - Check Filebeat is running: kubectl get pods -n logging -l app=filebeat"
echo "  - Check Filebeat logs: kubectl logs -n logging daemonset/filebeat"
echo "  - Verify index created: kubectl exec -n logging deployment/elasticsearch -- curl http://localhost:9200/_cat/indices"
echo ""
echo -e "${GREEN}ELK Stack setup complete!${NC}"
echo "======================================================================"
