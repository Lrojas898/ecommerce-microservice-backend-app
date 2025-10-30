#!/bin/bash

echo "Cleaning up and redeploying microservices..."

# Delete all deployments to force clean restart
echo "Deleting all deployments..."
kubectl delete deployment --all -n dev

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
sleep 10

# Apply all configurations
echo "Applying service configurations..."
kubectl apply -f infrastructure/kubernetes/base/ -n dev

# Wait for deployments to be created
echo "Waiting for deployments to be ready..."
sleep 30

# Check status
echo "Checking pod status..."
kubectl get pods -n dev

echo "Cleanup and redeploy completed!"