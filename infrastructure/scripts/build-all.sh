#!/bin/bash

# Script para construir TODOS los microservicios y subirlos a ECR
# Uso: ./build-all.sh [tag]

set -e

TAG=${1:-latest}
SERVICES=("user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

echo "🚀 Construyendo y subiendo TODOS los microservicios con tag: ${TAG}"
echo "================================================================"

for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "📦 Procesando: ${SERVICE}"
    echo "----------------------------------------------------------------"
    ./infrastructure/scripts/build-and-push.sh ${SERVICE} ${TAG}
    echo "✅ ${SERVICE} completado"
    echo ""
done

echo "================================================================"
echo "✅ TODOS los servicios fueron construidos y subidos exitosamente"
