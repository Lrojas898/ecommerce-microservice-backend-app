# Script para construir y hacer push de la imagen Jenkins
#!/bin/bash

set -e  # Exit on any error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DOCKER_HUB_REPO="luisrojasc"
IMAGE_NAME="jenkins-ecommerce"
JENKINS_VERSION="2.462.3-lts"
TAG="latest"
FULL_IMAGE_NAME="${DOCKER_HUB_REPO}/${IMAGE_NAME}:${TAG}"
VERSIONED_IMAGE_NAME="${DOCKER_HUB_REPO}/${IMAGE_NAME}:${JENKINS_VERSION}"

echo -e "${BLUE}🐳 Jenkins Docker Build and Push Script${NC}"
echo -e "${BLUE}=======================================${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Error: Dockerfile no encontrado. Ejecuta este script desde infrastructure/jenkins/${NC}"
    exit 1
fi

if [ ! -f "plugins.txt" ]; then
    echo -e "${RED}❌ Error: plugins.txt no encontrado${NC}"
    exit 1
fi

# Verificar Docker login
echo -e "${YELLOW}🔐 Verificando autenticación con Docker Hub...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está corriendo o no tienes permisos${NC}"
    exit 1
fi

# Solicitar credenciales si no está logueado
if ! docker system info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️ No estás autenticado con Docker Hub${NC}"
    echo -e "${BLUE}Por favor, haz login:${NC}"
    docker login
fi

# Mostrar información antes del build
echo -e "${BLUE}📋 Información del build:${NC}"
echo -e "  Repository: ${DOCKER_HUB_REPO}"
echo -e "  Image: ${IMAGE_NAME}"
echo -e "  Jenkins Version: ${JENKINS_VERSION}"
echo -e "  Tags: ${TAG}, ${JENKINS_VERSION}"
echo -e "  Full names: ${FULL_IMAGE_NAME}, ${VERSIONED_IMAGE_NAME}"
echo ""

# Construir la imagen
echo -e "${YELLOW}🏗️ Construyendo imagen Jenkins...${NC}"
echo -e "${BLUE}Comando: docker build -t ${FULL_IMAGE_NAME} -t ${VERSIONED_IMAGE_NAME} .${NC}"

if docker build --pull --no-cache -t "${FULL_IMAGE_NAME}" -t "${VERSIONED_IMAGE_NAME}" .; then
    echo -e "${GREEN}✅ Imagen construida exitosamente${NC}"
else
    echo -e "${RED}❌ Error construyendo la imagen${NC}"
    exit 1
fi

# Mostrar información de la imagen
echo -e "${BLUE}📊 Información de la imagen:${NC}"
docker images "${FULL_IMAGE_NAME}"

# Preguntar si hacer push
echo ""
read -p "¿Deseas hacer push de la imagen a Docker Hub? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📤 Haciendo push a Docker Hub...${NC}"
    
    # Push versión específica
    echo -e "${BLUE}Comando: docker push ${VERSIONED_IMAGE_NAME}${NC}"
    if docker push "${VERSIONED_IMAGE_NAME}"; then
        echo -e "${GREEN}✅ Push de versión ${JENKINS_VERSION} completado${NC}"
    else
        echo -e "${RED}❌ Error haciendo push de versión específica${NC}"
        exit 1
    fi
    
    # Push latest
    echo -e "${BLUE}Comando: docker push ${FULL_IMAGE_NAME}${NC}"
    if docker push "${FULL_IMAGE_NAME}"; then
        echo -e "${GREEN}✅ Push de latest completado${NC}"
        echo -e "${GREEN}🎉 Imagen disponible en: https://hub.docker.com/r/${DOCKER_HUB_REPO}/${IMAGE_NAME}${NC}"
    else
        echo -e "${RED}❌ Error haciendo push de latest${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⏸️ Push cancelado por el usuario${NC}"
    echo -e "${BLUE}💡 Para hacer push manualmente:${NC}"
    echo -e "  docker push ${VERSIONED_IMAGE_NAME}"
    echo -e "  docker push ${FULL_IMAGE_NAME}"
fi

# Mostrar comandos útiles
echo ""
echo -e "${BLUE}🚀 Comandos útiles:${NC}"
echo -e "  # Ejecutar Jenkins localmente:"
echo -e "  docker run -d -p 8080:8080 -p 50000:50000 \\"
echo -e "    -v jenkins_home:/var/jenkins_home \\"
echo -e "    -v /var/run/docker.sock:/var/run/docker.sock \\"
echo -e "    --name jenkins-ecommerce ${FULL_IMAGE_NAME}"
echo ""
echo -e "  # O usar docker-compose:"
echo -e "  docker-compose up -d"
echo ""
echo -e "  # Ver logs:"
echo -e "  docker logs -f jenkins-ecommerce"
echo ""
echo -e "${GREEN}✅ Proceso completado${NC}"