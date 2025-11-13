#!/bin/bash

###############################################################################
# SonarQube Deployment Script for Kubernetes
#
# This script deploys SonarQube with PostgreSQL backend to a Kubernetes cluster
#
# Usage: ./deploy-sonarqube.sh
#
# Requirements:
#   - kubectl configured and connected to cluster
#   - Sufficient cluster resources (4GB RAM minimum for SonarQube)
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="sonarqube"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Functions
###############################################################################

print_header() {
    echo ""
    echo "========================================"
    echo "  SonarQube Deployment for Kubernetes"
    echo "========================================"
    echo ""
}

print_step() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[INFO]${NC} ✓ $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} ⚠ $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} ✗ $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi

    print_success "Prerequisites check passed"
}

create_namespace() {
    print_step "Step 1: Creating namespace '${NAMESPACE}'..."

    if kubectl get namespace ${NAMESPACE} &> /dev/null; then
        print_warning "Namespace '${NAMESPACE}' already exists, skipping creation"
    else
        kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
        print_success "Namespace created"
    fi
}

deploy_sonarqube() {
    print_step "Step 2: Deploying SonarQube and PostgreSQL..."

    kubectl apply -f "${SCRIPT_DIR}/sonarqube.yaml"
    print_success "SonarQube manifests applied"
}

wait_for_postgres() {
    print_step "Step 3: Waiting for PostgreSQL to be ready..."

    kubectl wait --for=condition=ready pod \
        -l app=sonarqube-postgres \
        -n ${NAMESPACE} \
        --timeout=300s 2>/dev/null || true

    # Check if postgres is actually ready
    POSTGRES_READY=$(kubectl get pods -n ${NAMESPACE} -l app=sonarqube-postgres -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')

    if [ "$POSTGRES_READY" == "True" ]; then
        print_success "PostgreSQL is ready"
    else
        print_warning "PostgreSQL may not be ready yet. Checking logs..."
        kubectl logs -n ${NAMESPACE} -l app=sonarqube-postgres --tail=20
    fi
}

wait_for_sonarqube() {
    print_step "Step 4: Waiting for SonarQube to be ready (this may take 2-3 minutes)..."

    # Wait for pod to be running
    kubectl wait --for=condition=ready pod \
        -l app=sonarqube \
        -n ${NAMESPACE} \
        --timeout=600s 2>/dev/null || true

    # Additional wait for SonarQube to fully start
    print_step "Waiting for SonarQube to fully initialize..."
    sleep 30

    # Check SonarQube status
    SONARQUBE_READY=$(kubectl get pods -n ${NAMESPACE} -l app=sonarqube -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')

    if [ "$SONARQUBE_READY" == "True" ]; then
        print_success "SonarQube is ready"
    else
        print_warning "SonarQube may not be ready yet. Checking logs..."
        kubectl logs -n ${NAMESPACE} -l app=sonarqube --tail=20
    fi
}

get_access_info() {
    print_step "Step 5: Getting access information..."

    # Get NodePort
    NODEPORT=$(kubectl get svc sonarqube-external -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')

    # Try to get external IP
    EXTERNAL_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

    # If no external IP, try to get internal IP
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi

    echo ""
    echo "========================================"
    echo "  Deployment Successful!"
    echo "========================================"
    echo ""
    echo "📊 SonarQube is now accessible at:"
    echo ""
    echo "   URL: http://${EXTERNAL_IP}:${NODEPORT}"
    echo ""
    echo "🔐 Default Credentials:"
    echo "   Username: admin"
    echo "   Password: admin"
    echo "   (You will be prompted to change the password on first login)"
    echo ""
    echo "📝 Important Notes:"
    echo ""
    echo "   1. SonarQube may take a few minutes to fully start"
    echo "   2. Check status: kubectl get pods -n ${NAMESPACE}"
    echo "   3. View logs: kubectl logs -f deployment/sonarqube -n ${NAMESPACE}"
    echo ""
    echo "🔧 Next Steps:"
    echo ""
    echo "   1. Access SonarQube UI and change default password"
    echo "   2. Generate authentication tokens for your pipelines"
    echo "   3. Update Jenkins pipelines with the new SonarQube URL:"
    echo "      http://${EXTERNAL_IP}:${NODEPORT}"
    echo ""
    echo "========================================"
    echo ""
}

show_status() {
    echo "Current Status:"
    echo ""
    kubectl get all -n ${NAMESPACE}
    echo ""
}

###############################################################################
# Main Execution
###############################################################################

main() {
    print_header
    check_prerequisites
    create_namespace
    deploy_sonarqube
    wait_for_postgres
    wait_for_sonarqube
    get_access_info
    show_status
}

# Run main function
main
