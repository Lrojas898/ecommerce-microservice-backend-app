#!/bin/bash

# ============================================================
# E-Commerce Monitoring Stack Deployment Script
# ============================================================
# This script deploys Prometheus and Grafana to Kubernetes
# for monitoring all microservices
# ============================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}E-Commerce Monitoring Stack Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check cluster connectivity
print_info "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
print_info "✓ Connected to Kubernetes cluster"
echo ""

# Step 1: Create monitoring namespace
print_info "Step 1: Creating monitoring namespace..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
print_info "✓ Namespace created/verified"
echo ""

# Step 2: Deploy Prometheus
print_info "Step 2: Deploying Prometheus..."
kubectl apply -f "$SCRIPT_DIR/prometheus-config.yaml"
kubectl apply -f "$SCRIPT_DIR/prometheus.yaml"
print_info "✓ Prometheus deployed"
echo ""

# Step 3: Deploy Grafana
print_info "Step 3: Deploying Grafana..."
kubectl apply -f "$SCRIPT_DIR/grafana-config.yaml"
kubectl apply -f "$SCRIPT_DIR/grafana.yaml"
print_info "✓ Grafana deployed"
echo ""

# Step 4: Wait for deployments to be ready
print_info "Step 4: Waiting for deployments to be ready..."
echo ""

print_info "Waiting for Prometheus..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || {
    print_error "Prometheus deployment failed to become ready"
    exit 1
}
print_info "✓ Prometheus is ready"

print_info "Waiting for Grafana..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || {
    print_error "Grafana deployment failed to become ready"
    exit 1
}
print_info "✓ Grafana is ready"
echo ""

# Step 5: Get access information
print_info "Step 5: Getting access information..."
echo ""

# Get Minikube IP if using Minikube
MINIKUBE_IP=""
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "")
fi

# Get NodePort for Prometheus
PROMETHEUS_NODEPORT=$(kubectl get svc prometheus-external -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_NODEPORT=$(kubectl get svc grafana-external -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Monitoring Stack Components:"
echo ""

if [ -n "$MINIKUBE_IP" ]; then
    echo "📊 Prometheus UI:"
    echo "   URL: http://${MINIKUBE_IP}:${PROMETHEUS_NODEPORT}"
    echo ""
    echo "📈 Grafana UI:"
    echo "   URL: http://${MINIKUBE_IP}:${GRAFANA_NODEPORT}"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo ""
else
    echo "📊 Prometheus UI:"
    echo "   NodePort: ${PROMETHEUS_NODEPORT}"
    echo "   Access via: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    echo "   Then open: http://localhost:9090"
    echo ""
    echo "📈 Grafana UI:"
    echo "   NodePort: ${GRAFANA_NODEPORT}"
    echo "   Access via: kubectl port-forward -n monitoring svc/grafana 3000:3000"
    echo "   Then open: http://localhost:3000"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo ""
fi

echo "Useful Commands:"
echo ""
echo "  # View all monitoring resources"
echo "  kubectl get all -n monitoring"
echo ""
echo "  # View Prometheus logs"
echo "  kubectl logs -f deployment/prometheus -n monitoring"
echo ""
echo "  # View Grafana logs"
echo "  kubectl logs -f deployment/grafana -n monitoring"
echo ""
echo "  # Check Prometheus targets (via port-forward)"
echo "  kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "  # Then visit: http://localhost:9090/targets"
echo ""
echo "  # Delete monitoring stack"
echo "  kubectl delete namespace monitoring"
echo ""
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if microservices are exposing metrics
print_info "Checking if microservices are exposing Prometheus metrics..."
echo ""

NAMESPACES=("dev" "prod")
SERVICES=("user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service" "api-gateway" "service-discovery")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_info "Checking services in namespace: $ns"
        for svc in "${SERVICES[@]}"; do
            if kubectl get svc "$svc" -n "$ns" &> /dev/null; then
                echo "  ✓ $svc found in $ns"
            fi
        done
        echo ""
    fi
done

print_warning "NOTE: Make sure your microservices are deployed and exposing /actuator/prometheus endpoint"
print_warning "You can verify this by port-forwarding to a service and checking:"
print_warning "  kubectl port-forward -n dev svc/user-service 8081:8081"
print_warning "  curl http://localhost:8081/user-service/actuator/prometheus"
echo ""

print_info "Monitoring stack deployment completed successfully!"
