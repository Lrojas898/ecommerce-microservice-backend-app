#!/bin/bash
set -e

echo "=== Instalando herramientas en Jenkins Agent ==="

# Este script debe ejecutarse en el EC2 del Jenkins Agent
# Ejecutar como: bash setup-jenkins-agent-tools.sh

# Actualizar sistema
echo "Actualizando sistema..."
sudo yum update -y

# Instalar Git
echo "Instalando Git..."
sudo yum install -y git
git --version

# Instalar Java 17 (si no está instalado)
echo "Verificando Java 17..."
if ! command -v java &> /dev/null || ! java -version 2>&1 | grep -q "17"; then
    echo "Instalando Java 17..."
    sudo yum install -y java-17-amazon-corretto
    sudo alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-amazon-corretto/bin/java 2
    sudo alternatives --set java /usr/lib/jvm/java-17-amazon-corretto/bin/java
fi
java -version

# Instalar Docker (si no está instalado)
echo "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
fi
sudo systemctl status docker --no-pager | head -3

# Agregar usuario jenkins al grupo docker (si existe)
if id "jenkins" &>/dev/null; then
    sudo usermod -aG docker jenkins
    echo "Usuario jenkins agregado al grupo docker"
fi

# Instalar AWS CLI v2 (si no está instalado)
echo "Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "Instalando AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo yum install -y unzip
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi
aws --version

# Instalar kubectl (si no está instalado)
echo "Verificando kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi
kubectl version --client

# Instalar Maven
echo "Verificando Maven..."
if [ ! -d "/opt/maven" ]; then
    echo "Instalando Maven..."
    cd /opt
    sudo curl -LO https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
    sudo tar xzf apache-maven-3.9.5-bin.tar.gz
    sudo ln -s /opt/apache-maven-3.9.5 /opt/maven
    sudo rm apache-maven-3.9.5-bin.tar.gz
    cd -
fi

# Configurar variables de entorno para Maven
echo "Configurando variables de entorno..."
sudo tee /etc/profile.d/maven.sh > /dev/null << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF

sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# Verificar Maven
/opt/maven/bin/mvn --version

# Crear directorio de workspace para jenkins (si no existe)
if id "jenkins" &>/dev/null; then
    sudo mkdir -p /home/jenkins/workspace
    sudo chown -R jenkins:jenkins /home/jenkins
    echo "Directorio workspace configurado"
fi

echo ""
echo "=== Instalación completada en Jenkins Agent ==="
echo "Herramientas instaladas:"
echo "  - Git: $(git --version)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Docker: $(docker --version)"
echo "  - AWS CLI: $(aws --version)"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl OK')"
echo "  - Maven: $(/opt/maven/bin/mvn --version | head -1)"
echo ""
echo "IMPORTANTE: Cierra y vuelve a abrir la sesión para que las variables de entorno surtan efecto"
echo "O ejecuta: source /etc/profile.d/maven.sh"
