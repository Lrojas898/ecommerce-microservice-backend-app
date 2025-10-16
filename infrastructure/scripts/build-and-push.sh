#!/bin/bash

# Script para construir y subir imágenes Docker a ECR
# Uso: ./build-and-push.sh <service-name> <tag>

set -e

# Variables
SERVICE_NAME=$1
TAG=${2:-latest}
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="020951019497"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Validar parámetros
if [ -z "$SERVICE_NAME" ]; then
    echo "❌ Error: Debes especificar el nombre del servicio"
    echo "Uso: ./build-and-push.sh <service-name> [tag]"
    echo "Servicios disponibles: user-service, product-service, order-service, payment-service, shipping-service, favourite-service"
    exit 1
fi

echo "🔨 Construyendo ${SERVICE_NAME}..."

# Compilar con Maven
echo "📦 Compilando con Maven..."
mvn clean package -pl ${SERVICE_NAME} -am -DskipTests

# Construir imagen Docker
echo "🐳 Construyendo imagen Docker..."
docker build -t ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:${TAG} \
             -t ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:latest \
             -f ${SERVICE_NAME}/Dockerfile .

# Login a ECR
echo "🔐 Autenticando con ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Push a ECR
echo "📤 Subiendo imagen a ECR..."
docker push ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:${TAG}
docker push ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:latest

echo "✅ Imagen subida exitosamente:"
echo "   ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:${TAG}"
echo "   ${ECR_REGISTRY}/ecommerce/${SERVICE_NAME}:latest"
