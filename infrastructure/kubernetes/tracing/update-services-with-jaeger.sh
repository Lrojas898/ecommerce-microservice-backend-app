#!/bin/bash

# Script to add Jaeger tracing configuration to all microservices
# This script updates Kubernetes deployment manifests with Jaeger environment variables

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "  Adding Jaeger Configuration to Services"
echo "================================================"

# Get the base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$BASE_DIR/base"

# List of services to update
SERVICES=(
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
  "api-gateway"
  "service-discovery"
  "proxy-client"
)

# Function to add Jaeger configuration to a service
add_jaeger_config() {
  local service_name=$1
  local yaml_file="$SERVICES_DIR/${service_name}.yaml"

  echo -e "${BLUE}Processing ${service_name}...${NC}"

  if [ ! -f "$yaml_file" ]; then
    echo -e "${YELLOW}  Warning: $yaml_file not found, skipping...${NC}"
    return
  fi

  # Check if Jaeger config already exists
  if grep -q "SPRING_ZIPKIN_BASE_URL" "$yaml_file"; then
    echo -e "${YELLOW}  Already configured, skipping...${NC}"
    return
  fi

  # Create temporary file with Jaeger configuration
  TEMP_FILE=$(mktemp)

  # Add Jaeger configuration after EUREKA configuration
  awk -v service="$service_name" '
    /EUREKA_CLIENT_FETCH_REGISTRY/ {
      print
      getline
      print
      print "            # Jaeger Distributed Tracing Configuration"
      print "            - name: SPRING_ZIPKIN_BASE_URL"
      print "              value: \"http://jaeger-collector.tracing.svc.cluster.local:9411\""
      print "            - name: SPRING_SLEUTH_SAMPLER_PROBABILITY"
      print "              value: \"1.0\""
      print "            - name: SPRING_APPLICATION_NAME"
      print "              value: \"" service "\""
      next
    }
    {print}
  ' "$yaml_file" > "$TEMP_FILE"

  # Replace original file
  mv "$TEMP_FILE" "$yaml_file"

  echo -e "${GREEN}  ✓ Updated ${service_name}${NC}"
}

# Update all services
for service in "${SERVICES[@]}"; do
  add_jaeger_config "$service"
done

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  All services updated successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Deploy Jaeger: ./infrastructure/kubernetes/tracing/deploy-jaeger.sh"
echo "  3. Redeploy services to apply changes"
echo ""
