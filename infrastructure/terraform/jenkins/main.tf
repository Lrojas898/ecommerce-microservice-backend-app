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

# EC2 Instance for Jenkins (sin IAM profile - configurar AWS CLI manualmente después)
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.jenkins_instance_type
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data              = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }

  # Prevent accidental destruction of Jenkins server
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [user_data, ami]
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
