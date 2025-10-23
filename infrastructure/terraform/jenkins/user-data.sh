#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
yum install -y git

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install Maven
yum install -y maven

# Create directory for docker-compose
mkdir -p /opt/jenkins-sonarqube
cd /opt/jenkins-sonarqube

# Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock
      - JENKINS_UC=http://updates.jenkins.io
      - JENKINS_UC_EXPERIMENTAL=http://updates.jenkins.io/experimental
      - JENKINS_INCREMENTALS_REPO_MIRROR=http://repo.jenkins-ci.org/incrementals
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    user: root
    ports:
      - "8080:8080"
      - "8443:8443"
      - "50000:50000"
    volumes:
      - jenkins-data:/var/jenkins_home
      - jenkins-home:/home
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

  sonarqube:
    image: sonarqube:10.3-community
    container_name: sonarqube
    environment:
      - SONAR_WEB_HOST=0.0.0.0
      - SONAR_WEB_PORT=9000
      - SONAR_WEB_CONTEXT=/
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    restart: unless-stopped

volumes:
  jenkins-data: {}
  jenkins-home: {}
  sonarqube_data: {}
  sonarqube_logs: {}
  sonarqube_extensions: {}
EOF

# Start Jenkins and SonarQube with Docker Compose
docker-compose up -d

# Wait for Jenkins to start
sleep 45

# Get Jenkins initial password
JENKINS_PASSWORD=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Jenkins not ready yet")

# Save information for ec2-user
cat > /home/ec2-user/services-info.txt <<EOF
========================================
Jenkins & SonarQube Installation Complete
========================================

Services running in Docker containers:
- Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
- SonarQube: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000

Jenkins Initial Password: ${JENKINS_PASSWORD}

SonarQube Default Credentials:
  Username: admin
  Password: admin

To manage services:
  cd /opt/jenkins-sonarqube
  docker-compose ps          # View status
  docker-compose logs -f     # View logs
  docker-compose restart     # Restart services
  docker-compose down        # Stop services
  docker-compose up -d       # Start services

To access Jenkins container:
  docker exec -it jenkins bash

To access SonarQube container:
  docker exec -it sonarqube bash

========================================
EOF

chown ec2-user:ec2-user /home/ec2-user/services-info.txt

echo "Installation completed!" > /home/ec2-user/install-complete.txt
