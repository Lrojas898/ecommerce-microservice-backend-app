# Security Group for SonarQube
resource "aws_security_group" "sonarqube" {
  name        = "${var.project_name}-sonarqube-sg"
  description = "Security group for SonarQube server"

  # HTTP access for SonarQube UI
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SonarQube Web UI"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sonarqube-sg"
  }
}

# EC2 Instance for SonarQube
resource "aws_instance" "sonarqube" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.sonarqube_instance_type
  vpc_security_group_ids = [aws_security_group.sonarqube.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system
              dnf update -y

              # Install Docker
              dnf install -y docker
              systemctl start docker
              systemctl enable docker

              # Add ec2-user to docker group
              usermod -aG docker ec2-user

              # Run SonarQube container
              docker run -d \
                --name sonarqube \
                --restart unless-stopped \
                -p 9000:9000 \
                -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
                sonarqube:lts-community

              # Wait for SonarQube to be ready
              echo "SonarQube is starting... Access at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
              echo "Default credentials: admin / admin"
              EOF

  tags = {
    Name = "${var.project_name}-sonarqube"
  }
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Elastic IP for SonarQube
resource "aws_eip" "sonarqube" {
  instance = aws_instance.sonarqube.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-sonarqube-eip"
  }
}
