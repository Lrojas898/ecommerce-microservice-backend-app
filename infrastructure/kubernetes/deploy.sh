#!/bin/bash

# ============================================================
# E-Commerce Microservices Deployment Script
# ============================================================
# This script deploys all services in the correct order
# Usage: ./deploy.sh [prod|dev]
# ============================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}============================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}➜ $1${NC}"
}

wait_for_pod() {
    local label=$1
    local namespace=$2
    local timeout=${3:-300}

    print_info "Waiting for $label to be ready (timeout: ${timeout}s)..."

    if kubectl wait --for=condition=ready pod -l $label -n $namespace --timeout=${timeout}s 2>/dev/null; then
        print_success "$label is ready"
        return 0
    else
        print_warning "$label is not ready yet (continuing anyway)"
        return 1
    fi
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed"

    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"

    # Show cluster info
    print_info "Cluster: $(kubectl config current-context)"
    print_info "Nodes: $(kubectl get nodes --no-headers | wc -l)"
}

create_namespaces() {
    print_header "Creating Namespaces"

    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace '$NAMESPACE' ready"

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'monitoring' ready"

    kubectl create namespace tracing --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'tracing' ready"

    kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'logging' ready"
}

create_postgres_secret() {
    print_header "Creating PostgreSQL Secret"

    # Check if secret already exists
    if kubectl get secret postgres-secret -n $NAMESPACE &> /dev/null; then
        print_warning "PostgreSQL secret already exists (skipping)"
        return 0
    fi

    print_warning "PostgreSQL secret does not exist!"
    print_info "You need to create it manually with a secure password:"
    echo ""
    echo "  kubectl create secret generic postgres-secret \\"
    echo "    --from-literal=POSTGRES_PASSWORD='YOUR_SECURE_PASSWORD' \\"
    echo "    --from-literal=POSTGRES_USER='ecommerce_user' \\"
    echo "    --from-literal=POSTGRES_DB='ecommerce_users' \\"
    echo "    -n $NAMESPACE"
    echo ""
    read -p "Press ENTER after creating the secret, or Ctrl+C to cancel..."
}

deploy_postgresql() {
    print_header "Deploying PostgreSQL"

    kubectl apply -f postgres-deployment.yaml -n $NAMESPACE
    print_success "PostgreSQL deployed"

    wait_for_pod "app=postgresql" $NAMESPACE 300
}

deploy_service_discovery() {
    print_header "Deploying Service Discovery (Eureka)"

    kubectl apply -f base/service-discovery.yaml -n $NAMESPACE
    print_success "Service Discovery deployed"

    wait_for_pod "app=service-discovery" $NAMESPACE 300

    # Give Eureka extra time to fully start
    print_info "Waiting 30s for Eureka to stabilize..."
    sleep 30
}

deploy_microservices() {
    print_header "Deploying Microservices"

    local services=(
        "user-service"
        "product-service"
        "proxy-client"
        "order-service"
        "payment-service"
        "shipping-service"
        "favourite-service"
    )

    for service in "${services[@]}"; do
        print_info "Deploying $service..."
        kubectl apply -f base/${service}.yaml -n $NAMESPACE
        print_success "$service deployed"
        sleep 5  # Small delay between services
    done

    print_info "Waiting for microservices to be ready..."
    sleep 30
}

deploy_api_gateway() {
    print_header "Deploying API Gateway"

    kubectl apply -f base/api-gateway.yaml -n $NAMESPACE
    print_success "API Gateway deployed"

    wait_for_pod "app=api-gateway" $NAMESPACE 300
}

deploy_ingress() {
    print_header "Deploying Ingress"

    kubectl apply -f ingress.yaml
    print_success "Ingress deployed"

    print_info "Waiting for Ingress to get external IP..."
    sleep 10

    INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

    if [ "$INGRESS_IP" != "pending" ] && [ -n "$INGRESS_IP" ]; then
        print_success "Ingress IP: $INGRESS_IP"
    else
        print_warning "Ingress IP is still pending (this is normal, it may take a few minutes)"
    fi
}

verify_deployment() {
    print_header "Verifying Deployment"

    print_info "Pods in namespace '$NAMESPACE':"
    kubectl get pods -n $NAMESPACE

    echo ""
    print_info "Services in namespace '$NAMESPACE':"
    kubectl get svc -n $NAMESPACE

    echo ""
    print_info "Ingress:"
    kubectl get ingress -n $NAMESPACE

    echo ""
    PROBLEM_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)

    if [ $PROBLEM_PODS -gt 0 ]; then
        print_warning "$PROBLEM_PODS pod(s) not in Running state"
        kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded
    else
        print_success "All pods are running!"
    fi
}

show_access_info() {
    print_header "Access Information"

    INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

    if [ -n "$INGRESS_IP" ]; then
        echo -e "${GREEN}API Gateway URL: http://$INGRESS_IP${NC}"
        echo ""
        echo "Test endpoints:"
        echo "  curl http://$INGRESS_IP/actuator/health"
        echo "  curl http://$INGRESS_IP/app/api/products"
        echo ""
        echo "Eureka Dashboard:"
        echo "  curl http://$INGRESS_IP/eureka/web"
    else
        print_warning "Ingress IP not available yet"
        echo "Check later with: kubectl get ingress -n $NAMESPACE"
    fi
}

# ============================================================
# Main Script
# ============================================================

# Parse environment argument
NAMESPACE=${1:-prod}

if [ "$NAMESPACE" != "prod" ] && [ "$NAMESPACE" != "dev" ]; then
    print_error "Invalid namespace. Use: ./deploy.sh [prod|dev]"
    exit 1
fi

print_header "E-Commerce Microservices Deployment"
echo "Environment: $NAMESPACE"
echo "Cluster: $(kubectl config current-context)"
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

# Change to kubernetes directory
cd "$(dirname "$0")"

# Execute deployment steps
check_prerequisites
create_namespaces
create_postgres_secret
deploy_postgresql
deploy_service_discovery
deploy_microservices
deploy_api_gateway
deploy_ingress
verify_deployment
show_access_info

print_header "Deployment Complete!"
print_success "All services have been deployed to namespace '$NAMESPACE'"
echo ""
print_info "Monitor pods: kubectl get pods -n $NAMESPACE --watch"
print_info "View logs: kubectl logs -f -l app=api-gateway -n $NAMESPACE"
print_info "Port forward: kubectl port-forward -n $NAMESPACE svc/api-gateway 8080:80"
echo ""
