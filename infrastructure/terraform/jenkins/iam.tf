# IAM Role for Jenkins instances to use AWS Systems Manager
resource "aws_iam_role" "jenkins_ssm_role" {
  name = "${var.project_name}-jenkins-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-jenkins-ssm-role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "jenkins_ssm_policy" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS managed policy for ECR
resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Attach AWS managed policy for EKS
resource "aws_iam_role_policy_attachment" "jenkins_eks_policy" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_policy" "jenkins_secrets_policy" {
  name        = "${var.project_name}-jenkins-secrets-policy"
  description = "Allow Jenkins to access Secrets Manager for database credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:ecommerce-microservices-*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-jenkins-secrets-policy"
  }
}

# Attach custom Secrets Manager policy
resource "aws_iam_role_policy_attachment" "jenkins_secrets_policy_attachment" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = aws_iam_policy.jenkins_secrets_policy.arn
}

# IAM Instance Profile for Jenkins Master
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_ssm_role.name

  tags = {
    Name = "${var.project_name}-jenkins-profile"
  }
}

# IAM Instance Profile for Jenkins Agent
resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name = "${var.project_name}-jenkins-agent-profile"
  role = aws_iam_role.jenkins_ssm_role.name

  tags = {
    Name = "${var.project_name}-jenkins-agent-profile"
  }
}
