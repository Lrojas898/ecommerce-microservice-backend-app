#!/bin/bash
set -e

echo "==================================================================="
echo "Building Infrastructure Services Docker Images"
echo "==================================================================="

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="020951019497"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build service-discovery
echo ""
echo "==================================================================="
echo "Building service-discovery (Eureka)"
echo "==================================================================="
mvn clean install -pl service-discovery -am -DskipTests
docker build -t ${ECR_REGISTRY}/ecommerce/service-discovery:latest \
             -t ${ECR_REGISTRY}/ecommerce/service-discovery:staging \
             -t ${ECR_REGISTRY}/ecommerce/service-discovery:manual-build \
             -f service-discovery/Dockerfile .
echo "Pushing service-discovery..."
docker push ${ECR_REGISTRY}/ecommerce/service-discovery:latest
docker push ${ECR_REGISTRY}/ecommerce/service-discovery:staging
docker push ${ECR_REGISTRY}/ecommerce/service-discovery:manual-build
docker rmi ${ECR_REGISTRY}/ecommerce/service-discovery:manual-build || true

# Build cloud-config
echo ""
echo "==================================================================="
echo "Building cloud-config (Config Server)"
echo "==================================================================="
mvn clean install -pl cloud-config -am -DskipTests
docker build -t ${ECR_REGISTRY}/ecommerce/cloud-config:latest \
             -t ${ECR_REGISTRY}/ecommerce/cloud-config:staging \
             -t ${ECR_REGISTRY}/ecommerce/cloud-config:manual-build \
             -f cloud-config/Dockerfile .
echo "Pushing cloud-config..."
docker push ${ECR_REGISTRY}/ecommerce/cloud-config:latest
docker push ${ECR_REGISTRY}/ecommerce/cloud-config:staging
docker push ${ECR_REGISTRY}/ecommerce/cloud-config:manual-build
docker rmi ${ECR_REGISTRY}/ecommerce/cloud-config:manual-build || true

# Build api-gateway
echo ""
echo "==================================================================="
echo "Building api-gateway (API Gateway)"
echo "==================================================================="
mvn clean install -pl api-gateway -am -DskipTests
docker build -t ${ECR_REGISTRY}/ecommerce/api-gateway:latest \
             -t ${ECR_REGISTRY}/ecommerce/api-gateway:staging \
             -t ${ECR_REGISTRY}/ecommerce/api-gateway:manual-build \
             -f api-gateway/Dockerfile .
echo "Pushing api-gateway..."
docker push ${ECR_REGISTRY}/ecommerce/api-gateway:latest
docker push ${ECR_REGISTRY}/ecommerce/api-gateway:staging
docker push ${ECR_REGISTRY}/ecommerce/api-gateway:manual-build
docker rmi ${ECR_REGISTRY}/ecommerce/api-gateway:manual-build || true

echo ""
echo "==================================================================="
echo "All infrastructure services built and pushed successfully!"
echo "==================================================================="
echo ""
echo "Now restart the deployments in Kubernetes:"
echo "  kubectl rollout restart deployment/service-discovery -n staging"
echo "  kubectl rollout restart deployment/cloud-config -n staging"
echo "  kubectl rollout restart deployment/api-gateway -n staging"
echo ""
echo "After that, restart all other services:"
echo "  kubectl rollout restart deployment --all -n staging"
echo "==================================================================="
