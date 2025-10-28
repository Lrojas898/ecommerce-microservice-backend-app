#!/bin/bash

# Test script to verify the cleanup logic works as expected
K8S_NAMESPACE="dev"

echo "=== Current Replica Sets ==="
kubectl get rs -n $K8S_NAMESPACE | grep -v "0         0         0"

echo ""
echo "=== Cleaning up old replica sets with 0 replicas ==="

ALL_SERVICES="service-discovery,cloud-config,user-service,product-service,order-service,payment-service,shipping-service,favourite-service,proxy-client,api-gateway"

IFS=',' read -ra SERVICES <<< "$ALL_SERVICES"
for service in "${SERVICES[@]}"; do
    echo "Checking service: $service"
    
    # Find old replica sets with 0 replicas
    kubectl get rs -n $K8S_NAMESPACE -l app=$service -o name | while read rs; do
        DESIRED=$(kubectl get $rs -n $K8S_NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        CURRENT=$(kubectl get $rs -n $K8S_NAMESPACE -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
        
        if [ "$DESIRED" = "0" ] && [ "$CURRENT" = "0" ]; then
            echo "  Would delete: $rs (Desired: $DESIRED, Current: $CURRENT)"
            # Uncomment the next line to actually delete
            # kubectl delete $rs -n $K8S_NAMESPACE --ignore-not-found=true
        else
            echo "  Keeping: $rs (Desired: $DESIRED, Current: $CURRENT)"
        fi
    done
done

echo ""
echo "=== Current Pod Status ==="
kubectl get pods -n $K8S_NAMESPACE