#!/bin/bash
# Script para instalar Jenkins manualmente en la instancia EC2

JENKINS_IP="54.146.152.237"
SSH_KEY="$HOME/.ssh/jenkins-key.pem"

echo "=========================================="
echo "🔧 Instalando Jenkins manualmente"
echo "=========================================="
echo ""

# Verificar que existe la key
if [ ! -f "$SSH_KEY" ]; then
  echo "❌ No se encontró la key SSH en $SSH_KEY"
  exit 1
fi

# Conectar por SSH y ejecutar instalación
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$JENKINS_IP << 'ENDSSH'
set -e

echo "📦 Actualizando sistema..."
sudo dnf update -y

echo "☕ Instalando Java 17..."
sudo dnf install -y java-17-amazon-corretto-devel

echo "🔧 Instalando Jenkins..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins

echo "🐳 Instalando Docker..."
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

echo "📦 Instalando Git..."
sudo dnf install -y git

echo "☁️  Instalando AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

echo "☸️  Instalando kubectl..."
curl -sLO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "🔧 Instalando Maven..."
sudo dnf install -y maven

echo "🚀 Iniciando Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "⏳ Esperando a que Jenkins arranque..."
sleep 30

echo "🔑 Guardando contraseña inicial..."
sudo cat /var/lib/jenkins/secrets/initialAdminPassword > ~/jenkins-password.txt
chmod 644 ~/jenkins-password.txt

echo "✅ Instalación completada!"
echo ""
echo "📋 Contraseña inicial de Jenkins:"
cat ~/jenkins-password.txt
echo ""

ENDSSH

echo ""
echo "=========================================="
echo "✅ Jenkins instalado correctamente"
echo "=========================================="
echo ""
echo "🌐 URL: http://$JENKINS_IP:8080"
echo ""
echo "🔑 Para obtener la contraseña:"
echo "   ssh -i $SSH_KEY ec2-user@$JENKINS_IP cat ~/jenkins-password.txt"
echo ""
