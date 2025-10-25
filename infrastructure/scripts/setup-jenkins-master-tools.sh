#!/bin/bash
set -e

echo "=== Instalando herramientas en Jenkins Master ==="

# Este script debe ejecutarse DENTRO del contenedor de Jenkins
# Ejecutar como: docker exec -u root jenkins bash < setup-jenkins-master-tools.sh

# Actualizar repositorios
apt-get update -qq

# Instalar herramientas básicas
echo "Instalando herramientas básicas..."
apt-get install -y curl wget unzip git

# Instalar Maven
echo "Instalando Maven..."
apt-get install -y maven
mvn --version

# Instalar AWS CLI v2
echo "Instalando AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
aws --version

# Instalar kubectl
echo "Instalando kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

# Verificar Docker (ya debería estar disponible desde el host)
echo "Verificando Docker..."
docker --version

echo ""
echo "=== Instalación completada en Jenkins Master ==="
echo "Herramientas instaladas:"
echo "  - Git: $(git --version)"
echo "  - Maven: $(mvn --version | head -1)"
echo "  - AWS CLI: $(aws --version)"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl OK')"
echo "  - Docker: $(docker --version)"
