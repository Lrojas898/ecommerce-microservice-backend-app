#!/bin/bash
set -e

echo "=========================================="
echo "CONFIGURACIÓN COMPLETA DE JENKINS"
echo "=========================================="

# PASO 1: Limpiar todo lo anterior
echo ""
echo "[1/10] Limpiando contenedores anteriores..."
docker stop jenkins 2>/dev/null || true
docker rm jenkins 2>/dev/null || true
docker stop sonarqube 2>/dev/null || true
docker rm sonarqube 2>/dev/null || true

# PASO 2: Crear el contenedor de Jenkins con la configuración correcta
echo ""
echo "[2/10] Creando contenedor Jenkins con configuración correcta..."
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 -p 8443:8443 -p 50000:50000 \
  -v jenkins-sonarqube_jenkins-home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  --user root \
  jenkins/jenkins:lts

echo "Esperando 60 segundos a que Jenkins inicie..."
sleep 60

# PASO 3: Instalar todas las herramientas necesarias
echo ""
echo "[3/10] Instalando herramientas base (Docker CLI, Git, curl, etc)..."
docker exec -u root jenkins bash -c "
apt-get update -qq && \
apt-get install -y -qq \
  docker.io \
  curl \
  wget \
  git \
  unzip \
  gnupg \
  lsb-release \
  ca-certificates \
  vim \
  jq \
  python3 \
  python3-pip
"

# PASO 4: Instalar Maven si no existe (debería estar ya en la imagen)
echo ""
echo "[4/10] Verificando Maven..."
docker exec jenkins bash -c "
if ! command -v mvn &> /dev/null; then
  echo 'Instalando Maven...'
  apt-get install -y maven
else
  echo 'Maven ya está instalado'
fi
"

# PASO 5: Configurar permisos del socket Docker
echo ""
echo "[5/10] Configurando permisos de Docker..."
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# PASO 6: Verificar Docker
echo ""
echo "[6/10] Verificando Docker en Jenkins..."
docker exec jenkins docker ps

# PASO 7: Instalar AWS CLI v2
echo ""
echo "[7/10] Instalando AWS CLI v2..."
docker exec -u root jenkins bash -c "
cd /tmp && \
curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip && \
unzip -q awscliv2.zip && \
./aws/install && \
rm -rf awscliv2.zip aws
"

# PASO 8: Instalar kubectl
echo ""
echo "[8/10] Instalando kubectl..."
docker exec -u root jenkins bash -c "
curl -sLO 'https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl' && \
chmod +x kubectl && \
mv kubectl /usr/local/bin/
"

# PASO 8.5: Instalar herramientas adicionales opcionales
echo ""
echo "[8.5/10] Instalando herramientas adicionales (Locust para pruebas)..."
docker exec -u root jenkins bash -c "
pip3 install --quiet locust --break-system-packages 2>/dev/null || pip3 install --quiet locust || echo 'Locust installation skipped'
"

# PASO 9: Configurar credenciales AWS para root
echo ""
echo "[9/10] Configurando credenciales AWS..."
docker exec -u root jenkins bash -c "
mkdir -p /root/.aws
cat > /root/.aws/credentials <<'EOFCRED'
[default]
aws_access_key_id = AKIAQJYGHF7UXVENAXBY
aws_secret_access_key = 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
EOFCRED

cat > /root/.aws/config <<'EOFCONF'
[default]
region = us-east-2
output = json
EOFCONF

chmod 600 /root/.aws/credentials
chmod 600 /root/.aws/config
"

# PASO 10: Configurar credenciales AWS para usuario jenkins
echo ""
echo "[10/10] Configurando credenciales AWS para usuario jenkins..."
docker exec -u root jenkins bash -c "
mkdir -p /var/jenkins_home/.aws
cat > /var/jenkins_home/.aws/credentials <<'EOFCRED'
[default]
aws_access_key_id = AKIAQJYGHF7UXVENAXBY
aws_secret_access_key = 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
EOFCRED

cat > /var/jenkins_home/.aws/config <<'EOFCONF'
[default]
region = us-east-2
output = json
EOFCONF

chown -R 1000:1000 /var/jenkins_home/.aws
chmod 600 /var/jenkins_home/.aws/credentials
chmod 600 /var/jenkins_home/.aws/config
"

# PASO 11: Configurar kubectl para EKS
echo ""
echo "[11/11] Configurando kubectl para EKS..."
docker exec jenkins aws eks update-kubeconfig --region us-east-2 --name ecommerce-microservices-cluster

# Crear directorio .kube para jenkins user
docker exec -u root jenkins bash -c "
mkdir -p /var/jenkins_home/.kube
cp /root/.kube/config /var/jenkins_home/.kube/config
chown -R 1000:1000 /var/jenkins_home/.kube
"

# VERIFICACIONES FINALES
echo ""
echo "=========================================="
echo "VERIFICACIONES FINALES"
echo "=========================================="

echo ""
echo "✓ Docker:"
docker exec jenkins docker --version

echo ""
echo "✓ AWS CLI:"
docker exec jenkins aws --version

echo ""
echo "✓ AWS Credentials:"
docker exec jenkins aws sts get-caller-identity

echo ""
echo "✓ kubectl:"
docker exec jenkins kubectl version --client --short

echo ""
echo "✓ Kubernetes Cluster:"
docker exec jenkins kubectl get nodes

echo ""
echo "✓ Maven:"
docker exec jenkins mvn --version | head -1

echo ""
echo "✓ Git:"
docker exec jenkins git --version

echo ""
echo "✓ Java:"
docker exec jenkins java -version 2>&1 | head -1

echo ""
echo "✓ Python:"
docker exec jenkins python3 --version

echo ""
echo "=========================================="
echo "CONFIGURACIÓN COMPLETADA EXITOSAMENTE"
echo "=========================================="
echo ""
echo "Jenkins URL: http://3.12.227.83:8080"
echo ""
echo "SIGUIENTE PASO:"
echo "1. Ve a Jenkins: http://3.12.227.83:8080"
echo "2. Manage Jenkins → Credentials → System → Global → Add Credentials"
echo "3. Tipo: AWS Credentials"
echo "4. ID: aws-credentials-ecr"
echo "5. Access Key: AKIAQJYGHF7UXVENAXBY"
echo "6. Secret Key: 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"
echo ""
echo "Luego ejecuta el pipeline: ecommerce-build"
echo ""
echo "Contenedores corriendo:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
