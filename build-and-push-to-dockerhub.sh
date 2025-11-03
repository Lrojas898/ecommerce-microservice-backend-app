#!/bin/bash

# Script OPTIMIZADO para build local y subir imágenes a Docker Hub
# Versión 2.0 - Mucho más rápido usando jars precompilados

set -e  # Salir si hay algún error

# Configuración
DOCKER_USER="luisrojasc"
VERSION="0.1.0"
VERSION_TAG="v${VERSION}-$(date +%Y%m%d-%H%M%S)"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Mapeo de servicios a puertos
declare -A SERVICE_PORTS=(
    ["api-gateway"]="8080"
    ["cloud-config"]="9296"
    ["service-discovery"]="8761"
    ["proxy-client"]="8080"
    ["user-service"]="8081"
    ["product-service"]="8082"
    ["favourite-service"]="8086"
    ["order-service"]="8083"
    ["payment-service"]="8084"
    ["shipping-service"]="8085"
)

SERVICES=(
    "api-gateway"
    "cloud-config"
    "favourite-service"
    "order-service"
    "payment-service"
    "product-service"
    "proxy-client"
    "service-discovery"
    "shipping-service"
    "user-service"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Build & Push to Docker Hub (OPTIMIZADO)${NC}"
echo -e "${BLUE}  User: ${DOCKER_USER}${NC}"
echo -e "${BLUE}  Version: ${VERSION_TAG}${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. Login a Docker Hub
echo -e "\n${YELLOW}[1/5] Autenticando con Docker Hub...${NC}"
docker login -u ${DOCKER_USER}
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Autenticación exitosa${NC}"
else
    echo -e "${RED}✗ Error en autenticación${NC}"
    exit 1
fi

# 2. Compilar TODOS los servicios de una vez (mucho más rápido)
echo -e "\n${YELLOW}[2/5] Compilando TODOS los servicios con Maven...${NC}"
echo -e "${BLUE}Esto es más rápido que compilar uno por uno${NC}"
mvn clean package -DskipTests
echo -e "${GREEN}✓ Compilación completada${NC}"

# 3. Crear Dockerfiles optimizados y build de imágenes
echo -e "\n${YELLOW}[3/5] Construyendo imágenes Docker (usando jars precompilados)...${NC}"

build_service() {
    local SERVICE=$1
    local PORT=${SERVICE_PORTS[$SERVICE]}

    echo -e "\n${BLUE}>>> Building ${SERVICE}...${NC}"

    # Crear Dockerfile temporal optimizado
    cat > "${SERVICE}/Dockerfile.optimized" <<EOF
FROM openjdk:11-jre-slim
WORKDIR /app
COPY ${SERVICE}-v${VERSION}.jar app.jar
EXPOSE ${PORT}
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \\
  CMD curl -f http://localhost:${PORT}/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

    # Build imagen Docker (context es el directorio target del servicio)
    docker build -f "${SERVICE}/Dockerfile.optimized" \
        -t "${DOCKER_USER}/${SERVICE}:${VERSION}" \
        -t "${DOCKER_USER}/${SERVICE}:${VERSION_TAG}" \
        -t "${DOCKER_USER}/${SERVICE}:latest" \
        "${SERVICE}/target"

    # Limpiar Dockerfile temporal
    rm "${SERVICE}/Dockerfile.optimized"

    echo -e "${GREEN}✓ ${SERVICE} imagen creada${NC}"
}

# Build todos los servicios
for SERVICE in "${SERVICES[@]}"; do
    build_service "${SERVICE}"
done

# 4. Push a Docker Hub
echo -e "\n${YELLOW}[4/5] Subiendo imágenes a Docker Hub...${NC}"
for SERVICE in "${SERVICES[@]}"; do
    echo -e "\n${BLUE}>>> Pushing ${SERVICE}...${NC}"

    docker push ${DOCKER_USER}/${SERVICE}:${VERSION} &
    PUSH_PID1=$!
    docker push ${DOCKER_USER}/${SERVICE}:${VERSION_TAG} &
    PUSH_PID2=$!
    docker push ${DOCKER_USER}/${SERVICE}:latest &
    PUSH_PID3=$!

    # Esperar a que terminen los 3 push en paralelo
    wait $PUSH_PID1 $PUSH_PID2 $PUSH_PID3

    echo -e "${GREEN}✓ ${SERVICE} subido${NC}"
done

# 5. Resumen
echo -e "\n${YELLOW}[5/5] Resumen de imágenes subidas:${NC}"
echo -e "${BLUE}========================================${NC}"
for SERVICE in "${SERVICES[@]}"; do
    echo -e "${GREEN}✓${NC} ${DOCKER_USER}/${SERVICE}:${VERSION_TAG}"
    echo -e "  ${DOCKER_USER}/${SERVICE}:${VERSION}"
    echo -e "  ${DOCKER_USER}/${SERVICE}:latest"
done
echo -e "${BLUE}========================================${NC}"

echo -e "\n${GREEN}✓ ¡Todas las imágenes han sido construidas y subidas exitosamente!${NC}"
echo -e "\n${YELLOW}Mejoras en esta versión:${NC}"
echo -e "✓ Compilación única de todos los servicios (más rápido)"
echo -e "✓ Dockerfiles optimizados sin multi-stage build"
echo -e "✓ Push paralelo de tags (3x más rápido)"
echo -e "✓ Sin dependencia de Maven Central en Docker build"
echo -e "\n${YELLOW}Próximos pasos:${NC}"
echo -e "1. Actualizar manifiestos K8s: ${DOCKER_USER}/[service]:${VERSION_TAG}"
echo -e "2. Aplicar cambios: kubectl apply -f infrastructure/kubernetes/base/ -n dev"
echo -e "3. Verificar: kubectl get pods -n dev -w"
echo -e "4. Rollout restart: kubectl rollout restart deployment -n dev"