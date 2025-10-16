#!/bin/bash
set -e

# Update system
yum update -y

# Install Java 17
yum install -y java-17-amazon-corretto

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins
usermod -aG docker ec2-user

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

# Install Terraform
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform

# Configure Jenkins
systemctl start jenkins
systemctl enable jenkins

# Wait for Jenkins to start
sleep 30

# Save initial admin password
mkdir -p /home/ec2-user
cat /var/lib/jenkins/secrets/initialAdminPassword > /home/ec2-user/jenkins-password.txt
chown ec2-user:ec2-user /home/ec2-user/jenkins-password.txt

echo "Jenkins installation completed!" > /home/ec2-user/install-complete.txt
