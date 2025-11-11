#!/bin/bash

# Deploy Jaeger for Distributed Tracing
# This script deploys Jaeger All-in-One to Kubernetes

set -e

echo "================================================"
echo "  Deploying Jaeger Distributed Tracing"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${YELLOW}Step 1: Creating tracing namespace...${NC}"
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

echo ""
echo -e "${YELLOW}Step 2: Deploying Jaeger All-in-One...${NC}"
kubectl apply -f "$SCRIPT_DIR/jaeger-all-in-one.yaml"

echo ""
echo -e "${YELLOW}Step 3: Waiting for Jaeger to be ready...${NC}"
kubectl wait --namespace=tracing \
  --for=condition=ready pod \
  --selector=app=jaeger \
  --timeout=300s

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Jaeger Deployed Successfully!${NC}"
echo -e "${GREEN}================================================${NC}"

echo ""
echo "Jaeger UI Access:"
echo "  - Port-forward: kubectl port-forward -n tracing svc/jaeger-query 16686:16686"
echo "  - Then open: http://localhost:16686"
echo ""
echo "For Minikube:"
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
if [ "$MINIKUBE_IP" != "N/A" ]; then
  echo "  - Direct access: http://$MINIKUBE_IP:30686"
fi

echo ""
echo "Jaeger Collector Endpoints:"
echo "  - HTTP: http://jaeger-collector.tracing.svc.cluster.local:14268/api/traces"
echo "  - Zipkin: http://jaeger-collector.tracing.svc.cluster.local:9411"
echo "  - gRPC: jaeger-collector.tracing.svc.cluster.local:14250"

echo ""
echo "Verify deployment:"
echo "  kubectl get all -n tracing"
echo ""
