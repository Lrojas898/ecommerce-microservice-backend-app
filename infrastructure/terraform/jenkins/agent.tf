# Jenkins Agent EC2 Instance
resource "aws_instance" "jenkins_agent" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.jenkins_agent_instance_type
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data              = file("${path.module}/agent-user-data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-agent"
  }
}

# Elastic IP for Jenkins Agent (opcional)
resource "aws_eip" "jenkins_agent" {
  instance = aws_instance.jenkins_agent.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-jenkins-agent-eip"
  }
}
