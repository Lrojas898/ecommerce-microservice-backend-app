# Security Group for Jenkins - MUY PERMISIVO (solo para taller)
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server"

  # Permitir TODO el tráfico entrante (SOLO PARA TALLER)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir TODO el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

# User data script for Jenkins installation
data "template_file" "jenkins_user_data" {
  template = file("${path.module}/user-data.sh")
}

# EC2 Instance for Jenkins usando LabInstanceProfile
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.jenkins_instance_type
  iam_instance_profile   = "LabInstanceProfile"  # Profile de AWS Academy
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data              = data.template_file.jenkins_user_data.rendered

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-server"
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

# Elastic IP for Jenkins
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-jenkins-eip"
  }
}
