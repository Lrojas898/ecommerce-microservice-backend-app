#!/bin/bash
set -e

# Update system
yum update -y

# Install Java 11 (required for Jenkins agent)
yum install -y java-11-amazon-corretto

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Maven
cd /opt
wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar xzf apache-maven-3.9.5-bin.tar.gz
ln -s /opt/apache-maven-3.9.5 /opt/maven
rm apache-maven-3.9.5-bin.tar.gz

# Set environment variables
cat >> /etc/profile.d/maven.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF

chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# Create jenkins user and add to docker group
useradd -m -s /bin/bash jenkins
usermod -aG docker jenkins

# Create jenkins workspace directory
mkdir -p /home/jenkins/workspace
chown -R jenkins:jenkins /home/jenkins

echo "Jenkins Agent setup completed!"
